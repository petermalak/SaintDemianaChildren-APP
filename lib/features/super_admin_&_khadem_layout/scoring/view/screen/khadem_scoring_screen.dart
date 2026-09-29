import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/utils/role_helper.dart';
import '../../../../../core/services/excel_export_service.dart';
import '../../../../../core/widgets/class_export_selection_dialog.dart';
import '../../../../profile/repository/i_profile_repository.dart';
import '../../../../scoring/viewmodel/scoring_cubit/scoring_cubit.dart';
import '../../../../scoring/viewmodel/scoring_cubit/scoring_state.dart';
import '../../../../scoring/repository/i_scoring_repository.dart';
import '../../../../scoring/model/scoring_models.dart';
import '../../../../authentication/model/user_model.dart';

class KhademScoringScreen extends StatefulWidget {
  final ScrollController? scrollController;

  const KhademScoringScreen({
    Key? key,
    this.scrollController,
  }) : super(key: key);

  @override
  State<KhademScoringScreen> createState() => _KhademScoringScreenState();
}

class _KhademScoringScreenState extends State<KhademScoringScreen> {
  UserModel? _currentUser;
  String? _selectedClassId;
  String? _selectedClassName;
  bool _isLoadingClasses = false;
  List<UserClassInfo> _availableClasses = [];

  @override
  void initState() {
    super.initState();
    _currentUser = sl<IProfileRepository>().user;
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final user = _currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingClasses = true;
    });

    // Get khadem classes
    final khademClasses = RoleHelper.getKhademClasses(user);

    if (mounted) {
      setState(() {
        _availableClasses = khademClasses;
        if (khademClasses.isNotEmpty && _selectedClassId == null) {
          _selectedClassId = khademClasses.first.classId;
          _selectedClassName = khademClasses.first.className;
        }
        _isLoadingClasses = false;
      });
    }
  }

  Widget _buildClassSelector() {
    if (_isLoadingClasses) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: LinearProgressIndicator(),
      );
    }

    if (_availableClasses.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.info_outline,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد فصول متاحة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'يجب أن تكون خادماً في فصل لرؤية التقييم',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_availableClasses.length == 1) {
      // Only one class, show it as a header
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.emoji_events,
              color: AppColors.accentWhite,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'التايو',
                    style: TextStyle(
                      color: AppColors.accentWhite,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _selectedClassName ?? 'فصلي',
                    style: const TextStyle(
                      color: AppColors.accentWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Multiple classes - show dropdown
    return Padding(
      padding: const EdgeInsets.all(16),
      child: DropdownButtonFormField<String?>(
        value: _selectedClassId,
        decoration: const InputDecoration(
          labelText: 'اختر فصل',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          prefixIcon: Icon(Icons.emoji_events),
        ),
        items: _availableClasses
            .map(
              (classInfo) => DropdownMenuItem<String?>(
                value: classInfo.classId,
                child: Text(classInfo.className ?? 'فصل'),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedClassId = value;
              _selectedClassName = _availableClasses
                  .firstWhere((c) => c.classId == value)
                  .className;
            });
          }
        },
      ),
    );
  }

  void _loadLeaderboard(ScoringCubit cubit) {
    if (_selectedClassId != null && _selectedClassId!.isNotEmpty) {
      cubit.getLeaderboard(_selectedClassId!, limit: 100);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedClassId == null || _selectedClassId!.isEmpty) {
      return SingleChildScrollView(
        controller: widget.scrollController,
        child: Column(
          children: [
            _buildClassSelector(),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildClassSelector(),
        Expanded(
          child: BlocProvider(
            key: ValueKey('khadem_scoring_$_selectedClassId'),
            create: (context) {
              final cubit = ScoringCubit(sl<IScoringRepository>());
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadLeaderboard(cubit);
              });
              return cubit;
            },
            child: BlocBuilder<ScoringCubit, ScoringState>(
              builder: (context, state) {
                if (state is ScoringLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ScoringError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              _loadLeaderboard(context.read<ScoringCubit>()),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is LeaderboardLoaded) {
                  if (state.leaderboard.isEmpty) {
                    return const Center(
                      child: Text('لا توجد بيانات للوحة المتصدرين'),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      _loadLeaderboard(context.read<ScoringCubit>());
                    },
                    child: Column(
                      children: [
                        _buildExportButton(state.leaderboard),
                        Expanded(
                          child: ListView.builder(
                            controller: widget.scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: state.leaderboard.length,
                            itemBuilder: (context, index) {
                              final entry = state.leaderboard[index];
                              return _buildLeaderboardEntry(entry);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return const Center(child: Text('لا توجد بيانات'));
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardEntry(LeaderboardEntryModel entry) {
    Color? rankColor;
    IconData? medalIcon;

    switch (entry.rank) {
      case 1:
        rankColor = Colors.amber;
        medalIcon = Icons.emoji_events;
        break;
      case 2:
        rankColor = Colors.grey[400];
        medalIcon = Icons.emoji_events;
        break;
      case 3:
        rankColor = Colors.brown[300];
        medalIcon = Icons.emoji_events;
        break;
      default:
        rankColor = Colors.grey[600];
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: SizedBox(
          width: 50,
          child: Row(
            children: [
              if (medalIcon != null)
                Icon(medalIcon, color: rankColor, size: 24)
              else
                Text(
                  '#${entry.rank}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: rankColor,
                  ),
                ),
            ],
          ),
        ),
        title: Text(
          entry.user?.name ?? 'غير معروف',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: entry.tier != null
            ? Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 16,
                    color: _parseColor(entry.tier!.color),
                  ),
                  const SizedBox(width: 4),
                  Text(entry.tier!.name),
                ],
              )
            : null,
        trailing: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.totalPoints}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'نقطة',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null) return Colors.grey;
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  Widget _buildExportButton(List<LeaderboardEntryModel> leaderboard) {
    if (leaderboard.isEmpty) return const SizedBox.shrink();

    final hasMultipleClasses = _availableClasses.length > 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: () async {
          if (hasMultipleClasses) {
            // Show class selection dialog
            final selectedClassIds = await showDialog<List<String>>(
              context: context,
              builder: (context) => ClassExportSelectionDialog(
                availableClasses: _availableClasses
                    .map((c) =>
                        ClassOption(id: c.classId, name: c.className ?? ''))
                    .toList(),
                title: 'اختر الفصول لتصدير التايو',
              ),
            );

            if (selectedClassIds == null || selectedClassIds.isEmpty) {
              return; // User cancelled
            }

            // Fetch leaderboard for each selected class
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(
                    'جاري جلب البيانات من ${selectedClassIds.length} فصل...'),
                duration: const Duration(seconds: 2),
              ),
            );

            final allLeaderboard = <LeaderboardEntryModel>[];
            final classNamesMap = {
              for (var classInfo in _availableClasses)
                classInfo.classId: classInfo.className ?? ''
            };
            // Map to track which class each user belongs to (userId -> classId)
            final userClassMap = <String, String>{};

            // Fetch data for each selected class
            final scoringRepo = sl<IScoringRepository>();
            for (final classId in selectedClassIds) {
              final result = await scoringRepo.getLeaderboard(
                classId,
                limit: 100,
                offset: 0,
              );

              result.fold(
                (error) {
                  print(
                      'Error fetching leaderboard for class $classId: $error');
                },
                (leaderboardData) {
                  // Track classId for each user
                  for (final entry in leaderboardData) {
                    userClassMap[entry.userId] = classId;
                  }
                  allLeaderboard.addAll(leaderboardData);
                },
              );
            }

            if (allLeaderboard.isEmpty) {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('لا توجد بيانات تايو في الفصول المحددة'),
                  backgroundColor: AppColors.warning,
                ),
              );
              return;
            }

            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(
                    'جاري تصدير ${allLeaderboard.length} سجل من ${selectedClassIds.length} فصل...'),
                duration: const Duration(seconds: 2),
              ),
            );

            final className = selectedClassIds.length == 1
                ? classNamesMap[selectedClassIds.first]
                : 'عدة_فصول';

            // Create a map for class names by userId
            final userClassNamesMap = <String, String>{};
            for (final entry in allLeaderboard) {
              final classId = userClassMap[entry.userId];
              if (classId != null) {
                userClassNamesMap[entry.userId] = classNamesMap[classId] ?? '';
              }
            }

            final result = await ExcelExportService.exportScoring(
              allLeaderboard,
              className,
              userClassNamesMap: selectedClassIds.length > 1 ? userClassNamesMap : null,
            );

            if (result != null) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: const Text('تم تصدير البيانات بنجاح'),
                  backgroundColor: AppColors.success,
                ),
              );
            } else {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: const Text('حدث خطأ أثناء التصدير'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          } else {
            // Single class - export current data
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('جاري تصدير البيانات...'),
                duration: Duration(seconds: 1),
              ),
            );

            final result = await ExcelExportService.exportScoring(
              leaderboard,
              _selectedClassName,
            );

            if (result != null) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: const Text('تم تصدير البيانات بنجاح'),
                  backgroundColor: AppColors.success,
                ),
              );
            } else {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: const Text('حدث خطأ أثناء التصدير'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
        icon: const Icon(Icons.download),
        label: Text(hasMultipleClasses
            ? 'تصدير إلى Excel (اختر الفصول)'
            : 'تصدير إلى Excel'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryMaroon,
          foregroundColor: AppColors.accentWhite,
        ),
      ),
    );
  }
}
