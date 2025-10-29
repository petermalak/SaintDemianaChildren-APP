import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../viewmodel/scoring_cubit/scoring_cubit.dart';
import '../../viewmodel/scoring_cubit/scoring_state.dart';
import '../../model/scoring_models.dart';

class LeaderboardScreen extends StatefulWidget {
  final String classId;

  const LeaderboardScreen({
    Key? key,
    required this.classId,
  }) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  void _loadLeaderboard() {
    context.read<ScoringCubit>().getLeaderboard(widget.classId, limit: 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة المتصدرين'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadLeaderboard();
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
                      onPressed: _loadLeaderboard,
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

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.leaderboard.length,
                itemBuilder: (context, index) {
                  final entry = state.leaderboard[index];
                  return _buildLeaderboardEntry(entry);
                },
              );
            }

            return const Center(child: Text('لا توجد بيانات'));
          },
        ),
      ),
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
        trailing: Column(
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
}
