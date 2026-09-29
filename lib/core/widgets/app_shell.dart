import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';

class AppTabItem {
  final IconData icon;
  final String label;

  const AppTabItem({required this.icon, required this.label});
}

/// Shared frame for khadem and makhdoum: named header, content, thumb-friendly tabs.
class AppShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData headerIcon;
  final List<Widget> actions;
  final List<AppTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final Widget body;
  final Widget? floatingActionButton;

  const AppShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.headerIcon,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.body,
    this.actions = const [],
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 72,
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentWhite.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(headerIcon, color: AppColors.accentWhite, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.accentWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.accentWhite.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: actions,
        ),
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: _AppBottomTabs(
          tabs: tabs,
          selectedIndex: selectedIndex,
          onTabSelected: onTabSelected,
        ),
      ),
    );
  }
}

class _AppBottomTabs extends StatefulWidget {
  final List<AppTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _AppBottomTabs({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  State<_AppBottomTabs> createState() => _AppBottomTabsState();
}

class _AppBottomTabsState extends State<_AppBottomTabs> {
  static const _tabWidth = 88.0;

  final _controller = ScrollController();
  bool _canScrollStart = false;
  bool _canScrollEnd = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateOverflow);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateOverflow();
      _ensureSelectedVisible(animated: false);
    });
  }

  @override
  void didUpdateWidget(covariant _AppBottomTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.tabs.length != widget.tabs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateOverflow();
        _ensureSelectedVisible(animated: true);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateOverflow() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final start = position.pixels > 6;
    final end = position.maxScrollExtent - position.pixels > 6;
    if (start != _canScrollStart || end != _canScrollEnd) {
      setState(() {
        _canScrollStart = start;
        _canScrollEnd = end;
      });
    }
  }

  void _ensureSelectedVisible({required bool animated}) {
    if (!_controller.hasClients) return;
    final index = widget.selectedIndex.clamp(0, widget.tabs.length - 1);
    final target = (index * _tabWidth) - 12;
    final max = _controller.position.maxScrollExtent;
    final offset = target.clamp(0.0, max);
    if (animated) {
      _controller.animateTo(
        offset,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _controller.jumpTo(offset);
    }
  }

  void _nudge(bool towardEnd) {
    if (!_controller.hasClients) return;
    final delta = towardEnd ? _tabWidth * 2 : -_tabWidth * 2;
    final next = (_controller.offset + delta)
        .clamp(0.0, _controller.position.maxScrollExtent);
    _controller.animateTo(
      next,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundCard,
      elevation: 8,
      child: SafeArea(
        top: false,
        bottom: false,
        child: SizedBox(
          height: 68,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fits = widget.tabs.length * _tabWidth <= constraints.maxWidth;
              if (fits) {
                return Row(
                  children: [
                    for (var i = 0; i < widget.tabs.length; i++)
                      Expanded(
                        child: _TabButton(
                          item: widget.tabs[i],
                          selected: widget.selectedIndex == i,
                          onTap: () => widget.onTabSelected(i),
                        ),
                      ),
                  ],
                );
              }

              return Stack(
                children: [
                  NotificationListener<ScrollMetricsNotification>(
                    onNotification: (_) {
                      _updateOverflow();
                      return false;
                    },
                    child: ListView.builder(
                      controller: _controller,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      itemExtent: _tabWidth,
                      itemCount: widget.tabs.length,
                      itemBuilder: (context, i) => _TabButton(
                        item: widget.tabs[i],
                        selected: widget.selectedIndex == i,
                        onTap: () => widget.onTabSelected(i),
                      ),
                    ),
                  ),
                  if (_canScrollStart)
                    _ScrollHint(
                      towardEnd: false,
                      onTap: () => _nudge(false),
                    ),
                  if (_canScrollEnd)
                    _ScrollHint(
                      towardEnd: true,
                      onTap: () => _nudge(true),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ScrollHint extends StatelessWidget {
  final bool towardEnd;
  final VoidCallback onTap;

  const _ScrollHint({required this.towardEnd, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final atStartEdge = isRtl ? towardEnd : !towardEnd;
    return Positioned(
      left: atStartEdge ? 0 : null,
      right: atStartEdge ? null : 0,
      top: 0,
      bottom: 0,
      width: 36,
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: atStartEdge ? Alignment.centerLeft : Alignment.centerRight,
              end: atStartEdge ? Alignment.centerRight : Alignment.centerLeft,
              colors: [
                AppColors.backgroundCard,
                AppColors.backgroundCard.withValues(alpha: 0),
              ],
            ),
          ),
          child: Icon(
            atStartEdge ? Icons.chevron_left : Icons.chevron_right,
            color: AppColors.primaryMaroon,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final AppTabItem item;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryMaroon : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primaryMaroon.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, size: 22, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

String firstNameOf(String? fullName, {required String fallback}) {
  final name = fullName?.trim();
  if (name == null || name.isEmpty) return fallback;
  return name.split(RegExp(r'\s+')).first;
}
