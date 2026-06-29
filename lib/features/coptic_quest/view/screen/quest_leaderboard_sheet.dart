import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../profile/repository/i_profile_repository.dart';
import '../../../scoring/repository/i_scoring_repository.dart';
import '../../coptic_quest_strings.dart';
import '../../theme/coptic_quest_colors.dart';

void showQuestLeaderboard(BuildContext context, String lang) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: CopticQuestColors.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _QuestLeaderboardSheet(lang: lang),
  );
}

class _QuestLeaderboardSheet extends StatefulWidget {
  final String lang;

  const _QuestLeaderboardSheet({required this.lang});

  @override
  State<_QuestLeaderboardSheet> createState() => _QuestLeaderboardSheetState();
}

class _QuestLeaderboardSheetState extends State<_QuestLeaderboardSheet> {
  bool _loading = true;
  String? _error;
  List<_RankRow> _rows = [];
  String? _myRank;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = sl<IProfileRepository>();
    final scoring = sl<IScoringRepository>();
    final user = profile.user;
    final classId = user?.classId;
    final userId = user?.id;

    if (classId == null || classId.isEmpty) {
      setState(() {
        _loading = false;
        _error = CopticQuestStrings.get('noClass', widget.lang);
      });
      return;
    }

    final leaderboardResult = await scoring.getLeaderboard(classId, limit: 10);
    String? rankLabel;
    if (userId != null) {
      final rankResult = await scoring.getUserRank(userId, classId);
      rankResult.fold((_) {}, (data) {
        final rank = data['rank'];
        if (rank != null) {
          rankLabel = '#$rank';
        }
      });
    }

    leaderboardResult.fold(
      (err) => setState(() {
        _loading = false;
        _error = err;
      }),
      (entries) => setState(() {
        _loading = false;
        _myRank = rankLabel;
        _rows = entries
            .map((e) => _RankRow(
                  rank: e.rank,
                  name: e.user?.name ?? e.userId,
                  points: e.totalPoints,
                  isMe: e.userId == userId,
                ))
            .toList();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CopticQuestColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CopticQuestStrings.get('leaderboard', widget.lang),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: CopticQuestColors.textDark,
                          ),
                        ),
                        Text(
                          CopticQuestStrings.get('leaderboardHint', widget.lang),
                          style: const TextStyle(
                            fontSize: 12,
                            color: CopticQuestColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_myRank != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: CopticQuestColors.funGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${CopticQuestStrings.get('yourRank', widget.lang)} $_myRank',
                        style: const TextStyle(
                          color: CopticQuestColors.funGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildBody(scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: CopticQuestColors.textMuted),
        ),
      );
    }
    if (_rows.isEmpty) {
      return Center(
        child: Text(
          CopticQuestStrings.get('leaderboardEmpty', widget.lang),
          style: const TextStyle(color: CopticQuestColors.textMuted),
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      itemCount: _rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final row = _rows[i];
        final medal = row.rank == 1
            ? '🥇'
            : row.rank == 2
                ? '🥈'
                : row.rank == 3
                    ? '🥉'
                    : '${row.rank}';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: row.isMe
                ? CopticQuestColors.funOrange.withValues(alpha: 0.12)
                : CopticQuestColors.skyBottom.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: row.isMe
                ? Border.all(color: CopticQuestColors.funOrange, width: 2)
                : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  medal,
                  style: TextStyle(
                    fontSize: row.rank <= 3 ? 22 : 16,
                    fontWeight: FontWeight.bold,
                    color: CopticQuestColors.textDark,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  row.name,
                  style: TextStyle(
                    fontWeight: row.isMe ? FontWeight.bold : FontWeight.w600,
                    color: CopticQuestColors.textDark,
                  ),
                ),
              ),
              Text(
                '${row.points} ⚡',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: CopticQuestColors.funOrange,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RankRow {
  final int rank;
  final String name;
  final int points;
  final bool isMe;

  _RankRow({
    required this.rank,
    required this.name,
    required this.points,
    required this.isMe,
  });
}
