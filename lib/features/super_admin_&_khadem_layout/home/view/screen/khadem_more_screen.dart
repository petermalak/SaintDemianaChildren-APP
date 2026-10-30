import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../feed/view/screen/feed_screen.dart';
import '../../../aftekad/view/screen/aftekad_screen.dart';
import '../../../members/view/screen/member_requests_screen.dart';
import '../../../scoring/view/screen/khadem_scoring_screen.dart';
import '../../../../shop/view/screen/khadem_shop_screen.dart';

class KhademMoreScreen extends StatefulWidget {
  const KhademMoreScreen({
    super.key,
    required this.hasShop,
    required this.hasScoring,
    this.shopClassId,
    this.initialPage,
    this.scrollController,
  });

  final bool hasShop;
  final bool hasScoring;
  final String? shopClassId;
  final String? initialPage;
  final ScrollController? scrollController;

  @override
  State<KhademMoreScreen> createState() => _KhademMoreScreenState();
}

class _KhademMoreScreenState extends State<KhademMoreScreen> {
  String? _page;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage;
  }

  @override
  Widget build(BuildContext context) {
    switch (_page) {
      case 'feed':
        return _pageShell('الأخبار', FeedScreen(scrollController: widget.scrollController));
      case 'eftekad':
        return _pageShell('الافتقاد', AftekadScreen(scrollController: widget.scrollController));
      case 'scoring':
        return _pageShell('التايو', KhademScoringScreen(scrollController: widget.scrollController));
      case 'requests':
        return _pageShell('طلبات الأعضاء', MemberRequestsScreen(scrollController: widget.scrollController));
      case 'shop':
        return _pageShell(
          'المتجر',
          KhademShopScreen(
            scrollController: widget.scrollController,
            initialClassId: widget.shopClassId,
          ),
        );
      default:
        return _menu();
    }
  }

  Widget _pageShell(String title, Widget child) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.arrow_forward, color: AppColors.primaryMaroon),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          onTap: () => setState(() => _page = null),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _menu() {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'المزيد',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _tile(Icons.newspaper_rounded, 'الأخبار', 'feed'),
        _tile(Icons.person_search_rounded, 'الافتقاد', 'eftekad'),
        _tile(Icons.how_to_reg_rounded, 'طلبات الأعضاء', 'requests'),
        if (widget.hasScoring) _tile(Icons.emoji_events_rounded, 'التايو', 'scoring'),
        if (widget.hasShop) _tile(Icons.storefront_rounded, 'المتجر', 'shop'),
      ],
    );
  }

  Widget _tile(IconData icon, String title, String page) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          leading: Icon(icon, color: AppColors.primaryMaroon),
          title: Text(title),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => setState(() => _page = page),
        ),
      ),
    );
  }
}
