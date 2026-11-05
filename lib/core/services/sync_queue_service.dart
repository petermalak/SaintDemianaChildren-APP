import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:saint_demiana_children/core/constants/api_endpoints.dart';
import 'package:saint_demiana_children/core/services/interface/i_storage_service.dart';
import 'package:saint_demiana_children/features/profile/repository/i_profile_repository.dart';

import '../di/service_locator.dart';
import 'data_refresh_cubit.dart';

const String kQueuedOperationMessage =
    'لا يوجد اتصال بالإنترنت. تم حفظ العملية على الجهاز وسيتم إرسالها تلقائياً عند عودة الاتصال، لا داعي لتكرارها.';

extension QueuedResponseX on Response {
  /// True when the request was not sent but stored in the offline queue.
  bool get isQueued =>
      statusCode == 202 && data is Map && (data as Map)['queued'] == true;
}

class SyncStatus {
  final int pending;
  final int failed;
  final bool syncing;

  /// Null until the first connection check finishes.
  final bool? online;

  /// The screen is showing data saved on the device.
  final bool usingCache;
  final DateTime? cachedAt;

  /// When false, queued actions stay on the device until the user sends them.
  final bool autoSync;

  const SyncStatus({
    this.pending = 0,
    this.failed = 0,
    this.syncing = false,
    this.online,
    this.usingCache = false,
    this.cachedAt,
    this.autoSync = true,
  });

  bool get isEmpty => pending == 0 && failed == 0;
}

class QueuedOperation {
  final String id;
  final String userId;
  final String method;
  final String path;
  final Map<String, dynamic>? queryParameters;
  final dynamic body;
  final DateTime createdAt;
  final int attempts;
  final bool failed;
  final String? error;

  const QueuedOperation({
    required this.id,
    required this.userId,
    required this.method,
    required this.path,
    required this.createdAt,
    this.queryParameters,
    this.body,
    this.attempts = 0,
    this.failed = false,
    this.error,
  });

  factory QueuedOperation.fromMap(Map map) => QueuedOperation(
        id: map['id'] as String,
        userId: map['userId'] as String,
        method: map['method'] as String,
        path: map['path'] as String,
        queryParameters: map['query'] is Map
            ? Map<String, dynamic>.from(map['query'] as Map)
            : null,
        body: _deepCopy(map['body']),
        createdAt: DateTime.parse(map['createdAt'] as String),
        attempts: map['attempts'] as int? ?? 0,
        failed: map['failed'] as bool? ?? false,
        error: map['error'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'method': method,
        'path': path,
        'query': queryParameters,
        'body': body,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'attempts': attempts,
        'failed': failed,
        'error': error,
      };

  QueuedOperation copyWith({int? attempts, bool? failed, String? error}) =>
      QueuedOperation(
        id: id,
        userId: userId,
        method: method,
        path: path,
        queryParameters: queryParameters,
        body: body,
        createdAt: createdAt,
        attempts: attempts ?? this.attempts,
        failed: failed ?? this.failed,
        error: error ?? this.error,
      );

  /// Short Arabic description shown in the sync status sheet.
  String get label {
    final action = switch (method) {
      'POST' => 'إضافة',
      'DELETE' => 'حذف',
      _ => 'تعديل',
    };
    final p = path.toLowerCase();
    final String target;
    if (p.startsWith('attendance')) {
      target = 'حضور';
    } else if (p.startsWith('eftekad')) {
      target = 'افتقاد';
    } else if (p.contains('points')) {
      target = 'نقاط';
    } else if (p.startsWith('scoring')) {
      target = 'إعدادات النقاط';
    } else if (p.startsWith('feeds')) {
      target = 'منشور';
    } else if (p.startsWith('shop')) {
      target = 'المتجر';
    } else if (p.startsWith('classes')) {
      target = 'فصل';
    } else if (p.startsWith('users')) {
      target = 'بيانات عضو';
    } else {
      target = path;
    }
    return '$action $target';
  }

  static dynamic _deepCopy(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _deepCopy(v)));
    }
    if (value is List) return value.map(_deepCopy).toList();
    return value;
  }
}

/// Stores write operations made while offline and replays them, in order, once the
/// device has a stable connection. Every operation carries an Idempotency-Key so the
/// backend applies it exactly once even if it is sent more than once.
class SyncQueueService with WidgetsBindingObserver {
  SyncQueueService._();
  static final SyncQueueService instance = SyncQueueService._();

  static const String _boxName = 'syncQueueBox';
  static const String _autoSyncKey = '__auto_sync';
  static const String idempotencyHeader = 'Idempotency-Key';
  static const String clientTimestampHeader = 'X-Client-Timestamp';
  static const String fromQueueExtra = 'fromSyncQueue';

  static const Duration _retryInterval = Duration(seconds: 30);
  static const Duration _maxBackoff = Duration(minutes: 10);

  /// Paths that need the server immediately and are never queued.
  static const List<String> _neverQueue = [
    ApiEndpoints.login,
    ApiEndpoints.logout,
    ApiEndpoints.changePassword,
    'notifications/token',
    ApiEndpoints.shopUploadGiftImage,
  ];

  final ValueNotifier<SyncStatus> status = ValueNotifier(const SyncStatus());

  Box? _box;
  Timer? _timer;
  Timer? _connectionTimer;
  bool _flushing = false;
  bool _autoSync = true;
  bool? _online;
  bool _usingCache = false;
  int _consecutiveFailures = 0;
  late Dio _dio;

  Future<void> init(Dio dio) async {
    _dio = dio;
    _box ??= await Hive.openBox(_boxName);
    _autoSync = _box!.get(_autoSyncKey) != false;
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
    _connectionTimer?.cancel();
    _connectionTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      unawaited(_checkConnection());
    });
    unawaited(_checkConnection());
    _scheduleNext(const Duration(seconds: 3));
  }

  void noteOnline() {
    _online = true;
    _usingCache = false;
    _refreshStatus();
  }

  void noteOffline({bool usingCache = false}) {
    _online = false;
    if (usingCache) _usingCache = true;
    _refreshStatus();
  }

  Future<void> setAutoSync(bool enabled) async {
    _autoSync = enabled;
    await _box?.put(_autoSyncKey, enabled);
    _refreshStatus();
    if (enabled) unawaited(flush());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) flush();
  }

  String? get _currentUserId => sl<IProfileRepository>().user?.id;

  bool isQueueable(RequestOptions options) {
    if (options.method == 'GET' || options.method == 'HEAD') return false;
    if (options.data is FormData) return false;
    if (options.extra[fromQueueExtra] == true) return false;
    final path = options.path;
    if (_neverQueue.any((p) => path.startsWith(p))) return false;
    final user = sl<IProfileRepository>().user;
    return user?.id != null &&
        user!.id!.isNotEmpty &&
        (user.token?.isNotEmpty ?? false);
  }

  /// Adds the headers that make a write safe to retry. Must run before the first attempt
  /// so a request that reached the server before the connection dropped is recognised.
  void tagRequest(RequestOptions options) {
    options.headers[idempotencyHeader] ??= _uuidV4();
    options.headers[clientTimestampHeader] ??=
        DateTime.now().toUtc().toIso8601String();
  }

  List<QueuedOperation> operationsForCurrentUser() {
    final userId = _currentUserId;
    if (_box == null || userId == null) return const [];
    final ops = _box!.values
        .whereType<Map>()
        .map(QueuedOperation.fromMap)
        .where((op) => op.userId == userId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return ops;
  }

  bool hasPendingForCurrentUser() =>
      operationsForCurrentUser().any((op) => !op.failed);

  Future<void> enqueue(RequestOptions options) async {
    final userId = _currentUserId;
    if (_box == null || userId == null) return;
    tagRequest(options);
    final op = QueuedOperation(
      id: options.headers[idempotencyHeader] as String,
      userId: userId,
      method: options.method,
      path: options.path,
      queryParameters:
          options.queryParameters.isEmpty ? null : options.queryParameters,
      body: QueuedOperation._deepCopy(options.data),
      createdAt:
          DateTime.parse(options.headers[clientTimestampHeader] as String),
    );
    await _box!.put(op.id, op.toMap());
    if (kDebugMode) print('📥 [SyncQueue] Queued ${op.method} ${op.path}');
    _refreshStatus();
    _scheduleNext(const Duration(seconds: 5));
  }

  Response queuedResponse(RequestOptions options) => Response(
        requestOptions: options,
        statusCode: 202,
        data: {
          'success': false,
          'queued': true,
          'message': kQueuedOperationMessage,
        },
      );

  Future<void> retry(String id) async {
    final raw = _box?.get(id);
    if (raw is! Map) return;
    final op = QueuedOperation.fromMap(raw);
    await _box!.put(id, op.copyWith(failed: false, attempts: 0).toMap());
    _refreshStatus();
    unawaited(flush());
  }

  Future<void> discard(String id) async {
    await _box?.delete(id);
    _refreshStatus();
  }

  Future<void> retryAllFailed() async {
    for (final op in operationsForCurrentUser().where((op) => op.failed)) {
      await _box!.put(op.id, op.copyWith(failed: false, attempts: 0).toMap());
    }
    _refreshStatus();
    unawaited(flush(manual: true));
  }

  Future<void> discardAll() async {
    for (final op in operationsForCurrentUser()) {
      await _box?.delete(op.id);
    }
    _refreshStatus();
  }

  /// Sends queued operations in the order they were made. Stops at the first network
  /// problem so later operations never overtake earlier ones.
  Future<void> flush({bool manual = false}) async {
    if (!manual && !_autoSync) return;
    if (_flushing || _box == null || _currentUserId == null) return;
    final pending =
        operationsForCurrentUser().where((op) => !op.failed).toList();
    if (pending.isEmpty) {
      _refreshStatus();
      return;
    }

    _flushing = true;
    _refreshStatus();
    var sent = 0;
    var networkProblem = false;
    try {
      final online = await _hasStableConnection(confirmTwice: !manual);
      _online = online;
      if (!online) {
        networkProblem = true;
        return;
      }
      _usingCache = false;

      for (final op in pending) {
        if (_currentUserId != op.userId) break;
        final outcome = await _send(op);
        if (outcome == _Outcome.done) {
          await _box!.delete(op.id);
          sent++;
        } else if (outcome == _Outcome.failed) {
          continue;
        } else {
          networkProblem = true;
          break;
        }
        _refreshStatus();
      }
    } finally {
      _flushing = false;
      _consecutiveFailures = networkProblem ? _consecutiveFailures + 1 : 0;
      _refreshStatus();
      if (sent > 0) sl<DataRefreshCubit>().refreshAll();
      if (hasPendingForCurrentUser()) _scheduleNext(_backoff());
    }
  }

  Future<_Outcome> _send(QueuedOperation op) async {
    try {
      final response = await _dio.request(
        op.path,
        data: op.body,
        queryParameters: op.queryParameters,
        options: Options(
          method: op.method,
          headers: {
            idempotencyHeader: op.id,
            clientTimestampHeader: op.createdAt.toUtc().toIso8601String(),
          },
          extra: {fromQueueExtra: true},
        ),
      );
      if (kDebugMode) {
        print('📤 [SyncQueue] Sent ${op.method} ${op.path} '
            '-> ${response.statusCode}');
      }
      return _Outcome.done;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == null) {
        await _box!.put(op.id, op.copyWith(attempts: op.attempts + 1).toMap());
        return _Outcome.retryLater;
      }
      // Already gone on the server (e.g. deleted from another device).
      if (code == 404 && op.method == 'DELETE') return _Outcome.done;
      if (code == 401 || code == 408 || code == 409 || code == 429 ||
          code >= 500) {
        await _box!.put(op.id, op.copyWith(attempts: op.attempts + 1).toMap());
        return _Outcome.retryLater;
      }
      final data = e.response?.data;
      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Error $code';
      await _box!.put(op.id, op.copyWith(failed: true, error: message).toMap());
      return _Outcome.failed;
    }
  }

  /// Reaches the real API. A manual send needs one success. Automatic sending
  /// waits for two successes a few seconds apart so a flicker does not start a sync.
  Future<bool> _hasStableConnection({bool confirmTwice = true}) async {
    if (!await _pingServer()) return false;
    if (!confirmTwice) return true;
    await Future.delayed(const Duration(seconds: 3));
    return _pingServer();
  }

  Future<bool> _pingServer() async {
    final probe = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ));
    try {
      final response = await probe.get(ApiEndpoints.appVersion);
      return (response.statusCode ?? 0) < 500;
    } catch (error) {
      if (error is DioException && error.response != null) {
        return (error.response!.statusCode ?? 500) < 500;
      }
      return false;
    }
  }

  Future<void> _checkConnection() async {
    final online = await _pingServer();
    if (_online == online && online) return;
    _online = online;
    if (online) _usingCache = false;
    _refreshStatus();
    if (online && _autoSync && hasPendingForCurrentUser()) {
      unawaited(flush());
    }
  }

  Duration _backoff() {
    if (_consecutiveFailures == 0) return _retryInterval;
    final seconds = _retryInterval.inSeconds * pow(2, _consecutiveFailures - 1);
    return Duration(seconds: min(seconds.toInt(), _maxBackoff.inSeconds));
  }

  void _scheduleNext(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, flush);
  }

  void _refreshStatus() {
    final ops = operationsForCurrentUser();
    status.value = SyncStatus(
      pending: ops.where((op) => !op.failed).length,
      failed: ops.where((op) => op.failed).length,
      syncing: _flushing,
      online: _online,
      usingCache: _usingCache,
      cachedAt: sl.isRegistered<IStorageService>()
          ? sl<IStorageService>().getLastCacheTime()
          : null,
      autoSync: _autoSync,
    );
  }

  /// Call after login/logout so the status reflects the current user's queue.
  void onUserChanged() {
    _refreshStatus();
    _scheduleNext(const Duration(seconds: 2));
  }

  static String _uuidV4() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

enum _Outcome { done, failed, retryLater }
