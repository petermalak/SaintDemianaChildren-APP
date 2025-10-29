import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_demiana_children/features/profile/repository/i_profile_repository.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/view/widget/member_card.dart';
import 'package:saint_demiana_children/features/super_admin_&_khadem_layout/members/viewmodel/get_members/get_members_cubit.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../authentication/model/user_model.dart';
import '../../repository/i_members_repository.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({
    super.key,
    required this.cardAnimation,
    this.onSelectionChanged,
    this.scrollController,
  });
  final Animation<double> cardAnimation;
  final ValueChanged<List<UserModel>>? onSelectionChanged;
  final ScrollController? scrollController;

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchMembers = [];
  final List<UserModel> _selectedMembers = [];
  late GetMembersCubit _membersCubit;
  bool _isGridView = true; // true for grid, false for list

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _membersCubit = GetMembersCubit(sl<IMembersRepository>())..getMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _membersCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return BlocProvider.value(
      value: _membersCubit,
      child: BlocBuilder<GetMembersCubit, GetMembersState>(
        builder: (context, state) {
          if (state is GetMembersLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is GetMembersFailure) {
            return Center(
              child: Text(
                state.errorMessage,
                style: const TextStyle(color: AppColors.error),
              ),
            );
          } else if (state is GetMembersSuccess) {
            // Filter out current user
            final currentUser = sl<IProfileRepository>().user;
            final filteredMembers = state.members
                .where((member) => member.id != currentUser?.id)
                .toList();

            return RefreshIndicator(
                onRefresh: () async {
                  _membersCubit.getMembers();
                },
                child: Column(
                  children: [
                    _buildSearchSection(filteredMembers),
                    _buildViewToggle(),
                    Expanded(
                      child: filteredMembers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: AppColors.primaryMaroon
                                        .withValues(alpha: 0.3.clamp(0.0, 1.0)),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchController.text.isEmpty
                                        ? 'لا يوجد أعضاء'
                                        : 'لا توجد نتائج للبحث',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.primaryMaroon.withValues(
                                          alpha: 0.7.clamp(0.0, 1.0)),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _isGridView
                              ? GridView.builder(
                                  controller: widget.scrollController,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        MediaQuery.of(context).size.width ~/
                                            180,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 1.2,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _searchController.text.isEmpty
                                      ? filteredMembers.length
                                      : _searchMembers.length,
                                  itemBuilder: (context, index) {
                                    final user = _searchController.text.isEmpty
                                        ? filteredMembers[index]
                                        : _searchMembers[index];
                                    return StatefulBuilder(
                                        builder: (context, set) {
                                      return MemberCard(
                                          selectedList: _selectedMembers,
                                          user: user,
                                          isCompact: true,
                                          onUpdate: () => set(() {}),
                                          cardAnimation: widget.cardAnimation,
                                          onSelectionChanged: (isSelected) =>
                                              _selectedMembers.length > 1
                                                  ? null
                                                  : setState(() {
                                                      widget.onSelectionChanged
                                                          ?.call(
                                                              _selectedMembers);
                                                    }));
                                    });
                                  },
                                )
                              : ListView.builder(
                                  controller: widget.scrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _searchController.text.isEmpty
                                      ? filteredMembers.length
                                      : _searchMembers.length,
                                  itemBuilder: (context, index) {
                                    final user = _searchController.text.isEmpty
                                        ? filteredMembers[index]
                                        : _searchMembers[index];
                                    return StatefulBuilder(
                                        builder: (context, set) {
                                      return MemberCard(
                                          selectedList: _selectedMembers,
                                          user: user,
                                          isCompact: true,
                                          isListView: true,
                                          onUpdate: () => set(() {}),
                                          cardAnimation: widget.cardAnimation,
                                          onSelectionChanged: (isSelected) =>
                                              _selectedMembers.length > 1
                                                  ? null
                                                  : setState(() {
                                                      widget.onSelectionChanged
                                                          ?.call(
                                                              _selectedMembers);
                                                    }));
                                    });
                                  },
                                ),
                    ),
                  ],
                ));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSearchSection(List<UserModel> members) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05.clamp(0.0, 1.0)),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'البحث عن الأعضاء...',
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryMaroon),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear,
                      color: AppColors.primaryMaroon
                          .withValues(alpha: 0.7.clamp(0.0, 1.0))),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() {
            _searchMembers = members
                .where((member) =>
                    member.name!.toLowerCase().contains(value.toLowerCase()) ||
                    member.email!.toLowerCase().contains(value.toLowerCase()) ||
                    member.phoneNumber!
                        .toLowerCase()
                        .contains(value.toLowerCase()))
                .toList();
          });
        },
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05.clamp(0.0, 1.0)),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.grid_view,
                    color: _isGridView
                        ? AppColors.primaryMaroon
                        : AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _isGridView = true;
                    });
                  },
                  tooltip: 'عرض الشبكة',
                ),
                IconButton(
                  icon: Icon(
                    Icons.list,
                    color: !_isGridView
                        ? AppColors.primaryMaroon
                        : AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _isGridView = false;
                    });
                  },
                  tooltip: 'عرض القائمة',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
