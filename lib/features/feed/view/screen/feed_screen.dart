import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:saint_demiana_children/core/di/service_locator.dart';
import 'package:saint_demiana_children/core/constants/app_colors.dart';
import 'package:saint_demiana_children/core/constants/spacing.dart';
import 'package:saint_demiana_children/features/authentication/model/user_model.dart';
import 'package:saint_demiana_children/features/feed/repository/i_feed_repository.dart';
import 'package:saint_demiana_children/features/feed/viewmodel/get_feed/get_feed_cubit.dart';
import 'package:saint_demiana_children/features/feed/viewmodel/add_feed/add_feed_cubit.dart';
import 'package:saint_demiana_children/features/feed/view/widget/feed_card.dart';
import 'package:saint_demiana_children/features/feed/view/widget/add_feed_dialog.dart';
import 'package:saint_demiana_children/features/profile/repository/i_profile_repository.dart';
import 'package:saint_demiana_children/core/services/interface/i_notification_service.dart';

class FeedScreen extends StatefulWidget {
  final ScrollController? scrollController;
  final String? classId; // If provided, load feeds for specific class only
  final bool isReadOnly; // If true, hide add/edit/delete buttons

  const FeedScreen({
    super.key,
    this.scrollController,
    this.classId,
    this.isReadOnly = false,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late ScrollController _scrollController;
  String? _selectedType;
  int _currentOffset = 0;
  final int _limit = 20;
  StreamSubscription<RemoteMessage>? _notificationSubscription;
  List<UserClassInfo> _availableClasses = const [];
  String? _selectedClassFilter;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
    _setupNotificationListener();
    final profile = sl<IProfileRepository>().user;
    if (profile != null) {
      _availableClasses = profile.classes
          .where((info) =>
              info.membershipRole == 'khadem' ||
              profile.role == UserRole.superAdmin)
          .toList();
    }
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _setupNotificationListener() {
    // Listen to incoming feed notifications and auto-refresh
    final notificationService = sl<INotificationService>();
    _notificationSubscription =
        notificationService.onMessageReceived.listen((message) {
      final notificationType = message.data['type'];
      if (notificationType == 'feed' && mounted) {
        print('📬 Feed notification received, refreshing feeds...');
        // Auto-refresh feeds when a new feed notification is received
        _currentOffset = 0;
        _loadFeeds(refresh: true);
      }
    });
  }

  void _loadFeeds({bool refresh = false}) {
    if (refresh) _currentOffset = 0;

    if (widget.classId != null) {
      // Load feeds for specific class (for makhdoums)
      context.read<GetFeedCubit>().getFeedsByClass(
            widget.classId!,
            type: _selectedType,
          );
    } else if (_selectedClassFilter != null &&
        _selectedClassFilter!.isNotEmpty) {
      context.read<GetFeedCubit>().getFeedsByClass(
            _selectedClassFilter!,
            type: _selectedType,
          );
    } else {
      // Load all feeds for user's classes (for khadems/admins)
      context.read<GetFeedCubit>().getMyFeeds(
            type: _selectedType,
            limit: _limit,
            offset: _currentOffset,
          );
    }
  }

  Widget _buildClassFilterBar() {
    final user = sl<IProfileRepository>().user;
    final canFilter = user != null &&
        (user.role == UserRole.khadem || user.role == UserRole.superAdmin);
    if (!canFilter || _availableClasses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: DropdownButtonFormField<String?>(
        value: _selectedClassFilter,
        decoration: const InputDecoration(
          labelText: 'عرض فصل محدد',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.class_rounded),
        ),
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('جميع الفصول'),
          ),
          ..._availableClasses.map(
            (info) => DropdownMenuItem<String?>(
              value: info.classId,
              child: Text(info.className ?? 'فصل بدون اسم'),
            ),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _selectedClassFilter = value;
            _currentOffset = 0;
          });
          _loadFeeds(refresh: true);
        },
      ),
    );
  }

  void _onScroll() {
    // Disable pagination when loading by classId (it loads all feeds at once)
    if (widget.classId != null || _selectedClassFilter != null) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<GetFeedCubit>().state;
      if (state is GetFeedSuccess && state.hasMore) {
        _currentOffset += _limit;
        _loadFeeds();
      }
    }
  }

  void _onFilterChanged(String? type) {
    setState(() {
      _selectedType = type;
      _currentOffset = 0;
    });
    _loadFeeds(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final user = sl<IProfileRepository>().user!;
    final isKhadem =
        user.role == UserRole.khadem || user.role == UserRole.superAdmin;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => GetFeedCubit(sl<IFeedRepository>())
            ..getMyFeeds(limit: _limit, offset: 0),
        ),
        BlocProvider(
          create: (context) => AddFeedCubit(sl<IFeedRepository>()),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإعلانات'),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              onSelected: _onFilterChanged,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: null,
                  child: Text('الكل'),
                ),
                const PopupMenuItem(
                  value: 'announcement',
                  child: Text('إعلانات'),
                ),
                const PopupMenuItem(
                  value: 'reminder',
                  child: Text('تذكيرات'),
                ),
                const PopupMenuItem(
                  value: 'post',
                  child: Text('منشورات'),
                ),
                const PopupMenuItem(
                  value: 'link',
                  child: Text('روابط'),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.grey[100],
        body: Column(
          children: [
            if (widget.classId == null) _buildClassFilterBar(),
            Expanded(
              child: BlocConsumer<GetFeedCubit, GetFeedState>(
                listener: (context, state) {
                  if (state is GetFeedFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.errorMessage),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is GetFeedLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is GetFeedSuccess) {
                    final feeds = state.feeds;
                    if (feeds.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.primaryMaroon.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.feed_rounded,
                                size: 64,
                                color: AppColors.primaryMaroon.withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'لا توجد إعلانات',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isKhadem
                                  ? 'ابدأ بإضافة إعلانات لطلابك'
                                  : 'سيتم عرض الإعلانات من خادمك هنا',
                              style:
                                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: AppColors.primaryMaroon,
                      backgroundColor: Colors.white,
                      onRefresh: () async {
                        _loadFeeds(refresh: true);
                      },
                      child: ListView.separated(
                        controller: _scrollController,
                        cacheExtent: 480,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemBuilder: (context, index) {
                          if (index == feeds.length && state.hasMore) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(AppSpacing.md),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          return RepaintBoundary(
                            child: FeedCard(
                            feed: feeds[index],
                            isKhadem: isKhadem,
                            onDelete: (feedId) {
                              context.read<GetFeedCubit>().deleteFeed(feedId);
                            },
                            onEdit: (feed) {
                              final addFeedCubit = context.read<AddFeedCubit>();
                              showDialog(
                                context: context,
                                builder: (dialogContext) => BlocProvider.value(
                                  value: addFeedCubit,
                                  child: AddFeedDialog(existingFeed: feed),
                                ),
                              ).then((result) {
                                if (result == true) {
                                  _currentOffset = 0;
                                  context.read<GetFeedCubit>().getMyFeeds(
                                        type: _selectedType,
                                        limit: _limit,
                                        offset: 0,
                                      );
                                }
                              });
                            },
                          ),
                          );
                        },
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemCount: feeds.length + (state.hasMore ? 1 : 0),
                      ),
                    );
                  } else if (state is GetFeedLoadingMore) {
                    return RefreshIndicator(
                      color: AppColors.primaryMaroon,
                      backgroundColor: Colors.white,
                      onRefresh: () async {
                        _loadFeeds(refresh: true);
                      },
                      child: ListView.separated(
                        controller: _scrollController,
                        cacheExtent: 480,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemBuilder: (context, index) {
                          return RepaintBoundary(
                            child: FeedCard(
                            feed: state.feeds[index],
                            isKhadem: isKhadem,
                            onDelete: (feedId) {
                              context.read<GetFeedCubit>().deleteFeed(feedId);
                            },
                            onEdit: (feed) {
                              final addFeedCubit = context.read<AddFeedCubit>();
                              showDialog(
                                context: context,
                                builder: (dialogContext) => BlocProvider.value(
                                  value: addFeedCubit,
                                  child: AddFeedDialog(existingFeed: feed),
                                ),
                              ).then((result) {
                                if (result == true) {
                                  _currentOffset = 0;
                                  context.read<GetFeedCubit>().getMyFeeds(
                                        type: _selectedType,
                                        limit: _limit,
                                        offset: 0,
                                      );
                                }
                              });
                            },
                          ),
                          );
                        },
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemCount: state.feeds.length,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
        floatingActionButton: (isKhadem && !widget.isReadOnly)
            ? Builder(
                builder: (btnContext) {
                  return FloatingActionButton.extended(
                    onPressed: () {
                      final addFeedCubit = btnContext.read<AddFeedCubit>();

                      showDialog(
                        context: btnContext,
                        builder: (dialogContext) => BlocProvider.value(
                          value: addFeedCubit,
                          child: const AddFeedDialog(),
                        ),
                      ).then((result) {
                        if (result == true) {
                          // Refresh feeds after adding
                          _loadFeeds(refresh: true);
                        }
                      });
                    },
                    icon: const Icon(Icons.add_rounded, size: 24),
                    label: const Text('إضافة إعلان',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    backgroundColor: AppColors.primaryMaroon,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }
}
