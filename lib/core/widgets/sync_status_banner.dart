import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../constants/app_colors.dart';
import '../services/sync_queue_service.dart';

/// Always-visible bar for the connection, saved data, and queued actions.
class SyncStatusBanner extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const SyncStatusBanner({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    final queue = SyncQueueService.instance;
    return ValueListenableBuilder<SyncStatus>(
      valueListenable: queue.status,
      builder: (context, status, _) {
        final hasFailed = status.failed > 0;
        final offline = status.online == false;
        final Color color;
        final IconData icon;
        final String text;

        if (status.syncing) {
          color = AppColors.primaryMaroon;
          icon = Icons.sync;
          text = 'جاري إرسال ${status.pending} عملية إلى الخادم...';
        } else if (hasFailed) {
          color = AppColors.error;
          icon = Icons.error_outline;
          text = '${status.failed} عملية لم يقبلها الخادم'
              '${status.pending > 0 ? ' • ${status.pending} في الانتظار' : ''}';
        } else if (offline) {
          color = const Color(0xFF8A5A00);
          icon = Icons.cloud_off;
          final saved = _savedText(status.cachedAt);
          text = status.usingCache || saved != null
              ? 'غير متصل • تعرض البيانات المحفوظة${saved == null ? '' : ' ($saved)'}'
              : 'غير متصل';
        } else if (status.pending > 0) {
          color = AppColors.primaryMaroon;
          icon = status.autoSync ? Icons.cloud_upload : Icons.pause_circle;
          text = status.autoSync
              ? '${status.pending} عملية في انتظار الإرسال'
              : '${status.pending} عملية متوقفة بانتظار إرسالك';
        } else if (status.online == null) {
          color = AppColors.primaryBlue;
          icon = Icons.cloud_queue;
          text = 'جاري التحقق من الاتصال...';
        } else {
          color = AppColors.success;
          icon = Icons.cloud_done;
          final saved = _savedText(status.cachedAt);
          text = saved == null ? 'متصل' : 'متصل • آخر حفظ $saved';
        }

        return Material(
          color: color,
          child: SafeArea(
            top: false,
            child: InkWell(
              onTap: _showDetails,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    status.syncing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(icon, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        text,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    const Icon(Icons.chevron_left,
                        size: 18, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String? _savedText(DateTime? time) {
    if (time == null) return null;
    return DateFormat('d/M HH:mm').format(time.toLocal());
  }

  void _showDetails() {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const Directionality(
        textDirection: TextDirection.rtl,
        child: _SyncQueueSheet(),
      ),
    );
  }
}

class _SyncQueueSheet extends StatelessWidget {
  const _SyncQueueSheet();

  @override
  Widget build(BuildContext context) {
    final queue = SyncQueueService.instance;
    final timeFormat = DateFormat('d/M HH:mm');
    return ValueListenableBuilder<SyncStatus>(
      valueListenable: queue.status,
      builder: (context, status, _) {
        final ops = queue.operationsForCurrentUser();
        final saved = status.cachedAt == null
            ? 'لا توجد بيانات محفوظة بعد'
            : 'آخر حفظ للبيانات: ${timeFormat.format(status.cachedAt!.toLocal())}';
        final connection = status.online == null
            ? 'جاري التحقق'
            : status.online!
                ? 'متصل بالخادم'
                : 'غير متصل';
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الاتصال والعمليات',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text('$connection • $saved',
                          style: TextStyle(color: AppColors.textSecondary)),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('إرسال تلقائي عند عودة الإنترنت'),
                        value: status.autoSync,
                        onChanged: status.syncing ? null : queue.setAutoSync,
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: status.syncing ? null : () => queue.flush(manual: true),
                            icon: const Icon(Icons.sync),
                            label: const Text('إرسال الآن'),
                          ),
                          TextButton.icon(
                            onPressed: status.failed == 0 || status.syncing
                                ? null
                                : queue.retryAllFailed,
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة الفاشل'),
                          ),
                          TextButton.icon(
                            onPressed: ops.isEmpty || status.syncing
                                ? null
                                : () => _confirmDiscardAll(context, queue),
                            icon: const Icon(Icons.delete_sweep),
                            label: const Text('حذف الكل'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (ops.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('لا توجد عمليات في الانتظار'),
                  ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: ops.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final op = ops[index];
                      return ListTile(
                        onTap: () => _showOperation(context, op, timeFormat),
                        leading: Icon(
                          op.failed ? Icons.error_outline : Icons.schedule,
                          color: op.failed
                              ? AppColors.error
                              : AppColors.textSecondary,
                        ),
                        title: Text(op.label),
                        subtitle: Text(
                          op.failed
                              ? 'رفض الخادم: ${op.error ?? ''}'
                              : 'في الانتظار منذ ${timeFormat.format(op.createdAt.toLocal())}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (op.failed)
                              IconButton(
                                tooltip: 'إعادة المحاولة',
                                icon: const Icon(Icons.refresh),
                                onPressed: () => queue.retry(op.id),
                              ),
                            IconButton(
                              tooltip: 'حذف من الجهاز',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => queue.discard(op.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDiscardAll(
      BuildContext context, SyncQueueService queue) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف كل العمليات؟'),
        content: const Text(
            'ستُحذف العمليات المحفوظة على الجهاز ولن تصل إلى الخادم.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true) await queue.discardAll();
  }

  void _showOperation(
      BuildContext context, QueuedOperation op, DateFormat timeFormat) {
    final body = op.body;
    final details = body is Map
        ? body.entries.take(6).map((e) => '${e.key}: ${e.value}').join('\n')
        : body?.toString();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(op.label),
        content: Text(
          'الوقت: ${timeFormat.format(op.createdAt.toLocal())}\n'
          'المسار: ${op.method} ${op.path}\n'
          'المحاولات: ${op.attempts}'
          '${op.error == null ? '' : '\nالسبب: ${op.error}'}'
          '${details == null || details.isEmpty ? '' : '\n\n$details'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
