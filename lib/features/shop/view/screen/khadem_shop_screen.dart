import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/core/constants/api_endpoints.dart';
import 'package:saint_demiana_children/core/constants/app_colors.dart';
import 'package:saint_demiana_children/core/di/service_locator.dart';
import 'package:saint_demiana_children/core/widgets/remote_image.dart';
import 'package:saint_demiana_children/features/shop/model/shop_gift_model.dart';
import 'package:saint_demiana_children/features/shop/model/shop_purchase_request_model.dart';
import 'package:saint_demiana_children/features/shop/repository/i_shop_repository.dart';
import 'package:saint_demiana_children/features/shop/view/widget/add_edit_gift_dialog.dart';
import 'package:saint_demiana_children/features/shop/viewmodel/khadem_shop/khadem_shop_cubit.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/super_admin/class_management/repository/i_class_repository.dart';

class KhademShopScreen extends StatefulWidget {
  final ScrollController? scrollController;
  final String? initialClassId;

  const KhademShopScreen({
    super.key,
    this.scrollController,
    this.initialClassId,
  });

  @override
  State<KhademShopScreen> createState() => _KhademShopScreenState();
}

class _KhademShopScreenState extends State<KhademShopScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => KhademShopCubit(
        sl<IShopRepository>(),
        sl<IClassRepository>(),
        initialClassId: widget.initialClassId,
        isSuperAdmin: false,
      )..loadClasses(),
      child: BlocListener<KhademShopCubit, KhademShopState>(
        listenWhen: (prev, curr) => curr.message != null,
        listener: (context, state) {
          final msg = state.message;
          if (msg == null || !context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor:
                  state.messageIsError ? AppColors.error : AppColors.success,
            ),
          );
          context.read<KhademShopCubit>().clearMessage();
        },
        child: BlocBuilder<KhademShopCubit, KhademShopState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () => context.read<KhademShopCubit>().refresh(),
              child: SingleChildScrollView(
                controller: widget.scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'متجر التايو',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (state.loadingClasses)
                      const Center(
                          child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ))
                    else if (state.classesWithShop.isEmpty)
                      _buildEmptyClasses()
                    else ...[
                      _buildClassSelector(context, state),
                      const SizedBox(height: 16),
                      _buildTabBar(),
                      const SizedBox(height: 12),
                      if (_tabIndex == 0)
                        _buildGiftsList(context, state)
                      else
                        _buildRequestsList(context, state),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyClasses() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shop_outlined, size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text(
            'لا يوجد فصل لديه متجر تايو',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'يمكن لمدير النظام تفعيل متجر التايو لأي فصل من إعدادات الفصل',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildClassSelector(BuildContext context, KhademShopState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: state.selectedClassId,
          isExpanded: true,
          hint: const Text('اختر الفصل'),
          items: state.classesWithShop
              .map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name),
                  ))
              .toList(),
          onChanged: (id) => context.read<KhademShopCubit>().selectClass(id),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: _tabIndex == 0
                ? AppColors.primaryMaroon
                : AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => setState(() => _tabIndex = 0),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      size: 20,
                      color: _tabIndex == 0
                          ? AppColors.accentWhite
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'الهدايا',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _tabIndex == 0
                            ? AppColors.accentWhite
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Material(
            color: _tabIndex == 1
                ? AppColors.primaryMaroon
                : AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => setState(() => _tabIndex = 1),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_checkout,
                      size: 20,
                      color: _tabIndex == 1
                          ? AppColors.accentWhite
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'طلبات الشراء',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _tabIndex == 1
                            ? AppColors.accentWhite
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGiftsList(BuildContext context, KhademShopState state) {
    if (state.loadingGifts) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final cubit = context.read<KhademShopCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: state.selectedClassId == null
                ? null
                : () => _showAddGift(context, state, cubit),
            icon: const Icon(Icons.add),
            label: const Text('إضافة هدية'),
          ),
        ),
        if (state.gifts.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'لا توجد هدايا. أضف هدية لعرضها للمخدومين.',
              textAlign: TextAlign.center,
            ),
          )
        else
          ...state.gifts.map((g) => _giftCard(context, g, cubit)),
      ],
    );
  }

  void _showAddGift(
      BuildContext context, KhademShopState state, KhademShopCubit cubit) {
    showDialog(
      context: context,
      builder: (ctx) => AddEditGiftDialog(
        classId: state.selectedClassId ?? state.classesWithShop.first.id,
        classes: state.classesWithShop,
        onSaved: () {
          cubit.loadGifts();
          cubit.loadRequests();
        },
      ),
    );
  }

  void _showEditGift(BuildContext context, KhademShopState state,
      ShopGiftModel gift, KhademShopCubit cubit) {
    showDialog(
      context: context,
      builder: (ctx) => AddEditGiftDialog(
        classId: gift.classId,
        classes: state.classesWithShop,
        gift: gift,
        onSaved: () {
          cubit.loadGifts();
          cubit.loadRequests();
        },
      ),
    );
  }

  Widget _giftCard(
      BuildContext context, ShopGiftModel g, KhademShopCubit cubit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: RemoteImage(
          path: g.imageUrl,
          size: 48,
          fallbackIcon: Icons.card_giftcard,
        ),
        title: Text(
          g.title,
          style: TextStyle(
            decoration: g.isVisible ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Text('${g.price} نقطة'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                g.isVisible ? Icons.visibility : Icons.visibility_off,
                color:
                    g.isVisible ? AppColors.success : AppColors.textSecondary,
              ),
              onPressed: () => cubit.toggleVisibility(g),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditGift(context, cubit.state, g, cubit),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: () => _confirmDeleteGift(context, g, cubit),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteGift(
      BuildContext context, ShopGiftModel gift, KhademShopCubit cubit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الهدية'),
        content: Text('هل أنت متأكد من حذف "${gift.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      cubit.deleteGift(gift);
    }
  }

  Widget _buildRequestsList(BuildContext context, KhademShopState state) {
    if (state.loadingRequests) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final pending = state.requests.where((r) => r.isPending).toList();
    final other = state.requests.where((r) => !r.isPending).toList();
    if (pending.isEmpty && other.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'لا توجد طلبات شراء',
          textAlign: TextAlign.center,
        ),
      );
    }
    final cubit = context.read<KhademShopCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pending.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'قيد الانتظار',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          ...pending
              .map((r) => _requestCard(r, showActions: true, cubit: cubit)),
          const SizedBox(height: 16),
        ],
        if (other.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'تمت معالجتها',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          ...other
              .map((r) => _requestCard(r, showActions: false, cubit: cubit)),
        ],
      ],
    );
  }

  Widget _requestCard(ShopPurchaseRequestModel r,
      {required bool showActions, required KhademShopCubit cubit}) {
    final userName = r.user?.name ?? 'مخدوم';
    final giftTitle = r.gift?.title ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    giftTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: r.isPending
                        ? AppColors.warning.withValues(alpha: 0.2)
                        : r.isApproved
                            ? AppColors.success.withValues(alpha: 0.2)
                            : AppColors.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    r.isPending
                        ? 'قيد الانتظار'
                        : r.isApproved
                            ? 'موافق عليه'
                            : 'مرفوض',
                    style: TextStyle(
                      fontSize: 12,
                      color: r.isPending
                          ? AppColors.warning
                          : r.isApproved
                              ? AppColors.success
                              : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('$userName - ${r.scoreAmount} نقطة'),
            if (showActions && r.isPending) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _rejectRequest(context, r, cubit),
                    child: const Text('رفض'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => cubit.approveRequest(r),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    child: const Text('موافقة'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _rejectRequest(BuildContext context, ShopPurchaseRequestModel r,
      KhademShopCubit cubit) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('رفض الطلب'),
          content: TextField(
            controller: c,
            decoration: const InputDecoration(
              labelText: 'سبب الرفض (اختياري)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                  ctx, c.text.trim().isEmpty ? null : c.text.trim()),
              child: const Text('رفض'),
            ),
          ],
        );
      },
    );
    if (context.mounted) {
      cubit.rejectRequest(r, reason: reason);
    }
  }
}
