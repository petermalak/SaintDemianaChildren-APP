import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/core/constants/api_endpoints.dart';
import 'package:saint_demiana_children/core/constants/app_colors.dart';
import 'package:saint_demiana_children/core/di/service_locator.dart';
import 'package:saint_demiana_children/core/widgets/remote_image.dart';
import 'package:saint_demiana_children/features/profile/repository/i_profile_repository.dart';
import 'package:saint_demiana_children/features/scoring/repository/i_scoring_repository.dart';
import 'package:saint_demiana_children/features/shop/model/shop_gift_model.dart';
import 'package:saint_demiana_children/features/shop/model/shop_purchase_request_model.dart';
import 'package:saint_demiana_children/features/shop/repository/i_shop_repository.dart';
import 'package:saint_demiana_children/features/shop/viewmodel/makhdoum_shop/makhdoum_shop_cubit.dart';

class MakhdoumShopScreen extends StatefulWidget {
  final ScrollController? scrollController;
  final String classId;
  final String? className;

  const MakhdoumShopScreen({
    super.key,
    this.scrollController,
    required this.classId,
    this.className,
  });

  @override
  State<MakhdoumShopScreen> createState() => _MakhdoumShopScreenState();
}

class _MakhdoumShopScreenState extends State<MakhdoumShopScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MakhdoumShopCubit(
        widget.classId,
        sl<IShopRepository>(),
        sl<IScoringRepository>(),
        sl<IProfileRepository>(),
      )..refresh(),
      child: BlocListener<MakhdoumShopCubit, MakhdoumShopState>(
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
          context.read<MakhdoumShopCubit>().clearMessage();
        },
        child: BlocBuilder<MakhdoumShopCubit, MakhdoumShopState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () => context.read<MakhdoumShopCubit>().refresh(),
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
                    if (state.loadingScore)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Center(
                            child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accentGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star,
                                  color: AppColors.accentGold),
                              const SizedBox(width: 8),
                              Text(
                                'رصيدك: ${state.myScore ?? 0} نقطة',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildTabBar(context, state),
                    const SizedBox(height: 16),
                    if (_tabIndex == 0)
                      _buildGiftsList(context, state)
                    else
                      _buildMyRequestsList(context, state),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, MakhdoumShopState state) {
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
                      Icons.list_alt,
                      size: 20,
                      color: _tabIndex == 1
                          ? AppColors.accentWhite
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'طلباتي',
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

  Widget _buildGiftsList(BuildContext context, MakhdoumShopState state) {
    if (state.loadingGifts) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.gifts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'لا توجد هدايا متاحة حالياً',
          textAlign: TextAlign.center,
        ),
      );
    }
    final cubit = context.read<MakhdoumShopCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: state.gifts
          .map((g) => _giftCard(context, g, state.myScore, cubit))
          .toList(),
    );
  }

  Widget _giftCard(BuildContext context, ShopGiftModel g, int? myScore,
      MakhdoumShopCubit cubit) {
    final canAfford = (myScore ?? 0) >= g.price;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: canAfford ? () => _requestPurchase(context, g, cubit) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              RemoteImage(
                path: g.imageUrl,
                size: 64,
                fallbackIcon: Icons.card_giftcard,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (g.description != null && g.description!.isNotEmpty)
                      Text(
                        g.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${g.price} نقطة',
                      style: TextStyle(
                        color: AppColors.accentGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (canAfford)
                Icon(Icons.shopping_cart, color: AppColors.primaryMaroon)
              else
                Text(
                  'نقاط غير كافية',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestPurchase(
      BuildContext context, ShopGiftModel gift, MakhdoumShopCubit cubit) async {
    final state = cubit.state;
    if ((state.myScore ?? 0) < gift.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('نقاطك غير كافية. لديك ${state.myScore ?? 0} نقطة.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('طلب شراء'),
        content: Text(
          'هل تريد طلب "${gift.title}" مقابل ${gift.price} نقطة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMaroon),
            child: const Text('نعم'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      cubit.requestPurchase(gift);
    }
  }

  Widget _buildMyRequestsList(BuildContext context, MakhdoumShopState state) {
    if (state.loadingRequests) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.myRequests.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'لم تقم بأي طلبات بعد',
          textAlign: TextAlign.center,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: state.myRequests.map((r) => _requestCard(r)).toList(),
    );
  }

  Widget _requestCard(ShopPurchaseRequestModel r) {
    final statusText = r.isPending
        ? 'قيد الانتظار'
        : r.isApproved
            ? 'موافق عليه'
            : 'مرفوض';
    final statusColor = r.isPending
        ? AppColors.warning
        : r.isApproved
            ? AppColors.success
            : AppColors.error;
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
                    r.gift?.title ?? '',
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
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(fontSize: 12, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${r.scoreAmount} نقطة'),
            if (r.rejectionReason != null && r.rejectionReason!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'سبب الرفض: ${r.rejectionReason}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
