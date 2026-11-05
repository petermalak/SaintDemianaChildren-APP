import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../repository/i_scoring_repository.dart';
import '../../viewmodel/scoring_cubit/scoring_cubit.dart';
import '../../viewmodel/scoring_cubit/scoring_state.dart';
import '../../model/scoring_models.dart';
import '../widget/user_score_card.dart';
import '../widget/tier_progress_widget.dart';
import '../widget/recent_transactions_widget.dart';
import 'leaderboard_screen.dart';
import 'transaction_history_screen.dart';

class ScoringDashboardScreen extends StatefulWidget {
  final String userId;
  final String classId;
  final String className;

  const ScoringDashboardScreen({
    Key? key,
    required this.userId,
    required this.classId,
    required this.className,
  }) : super(key: key);

  @override
  State<ScoringDashboardScreen> createState() => _ScoringDashboardScreenState();
}

class _ScoringDashboardScreenState extends State<ScoringDashboardScreen> {
  UserScoreModel? _cachedUserScore;
  List<ScoreTransactionModel>? _cachedTransactions;
  bool _hasLoadedTransactions = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    print(
        '🏆 [ScoringDashboard] Loading score for user: ${widget.userId}, class: ${widget.classId}');
    // Load user score
    context.read<ScoringCubit>().getUserScore(widget.userId, widget.classId);

    // Load transactions only once
    if (!_hasLoadedTransactions) {
      _hasLoadedTransactions = true;
      context.read<ScoringCubit>().getTransactionHistory(
            widget.userId,
            widget.classId,
            limit: 5,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    // If no classId, show error screen
    if (widget.classId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('نظام التايو'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 80,
                  color: Colors.orange,
                ),
                const SizedBox(height: 24),
                const Text(
                  'لست مسجلاً في فصل',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'يجب أن تكون مسجلاً في فصل لرؤية نقاطك',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'برجاء التواصل مع الخادم المسؤول',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('التايو - ${widget.className}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            tooltip: 'لوحة المتصدرين',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => ScoringCubit(sl<IScoringRepository>()),
                    child: LeaderboardScreen(classId: widget.classId),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: BlocConsumer<ScoringCubit, ScoringState>(
          listener: (context, state) {
            print('🏆 [ScoringDashboard] State changed: ${state.runtimeType}');
            if (state is ScoringError) {
              print('❌ [ScoringDashboard] Error: ${state.message}');
            }
            if (state is UserScoreLoaded) {
              print(
                  '✅ [ScoringDashboard] Score loaded: ${state.userScore.totalPoints} points');
              // Cache the userScore so it persists across state changes
              setState(() {
                _cachedUserScore = state.userScore;
              });
            }
            if (state is TransactionsLoaded) {
              print(
                  '✅ [ScoringDashboard] Transactions loaded: ${state.transactions.length} items');
              // Cache transactions
              setState(() {
                _cachedTransactions = state.transactions;
              });
            }
          },
          builder: (context, state) {
            print(
                '🏆 [ScoringDashboard] Building with state: ${state.runtimeType}, cached: ${_cachedUserScore != null}');

            // If we have cached score and not currently loading the main score, show dashboard
            if (_cachedUserScore != null && state is! ScoringLoading) {
              return _buildDashboard(context, _cachedUserScore!);
            }

            if (state is ScoringLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('جاري تحميل نقاطك...'),
                  ],
                ),
              );
            }

            if (state is ScoringError) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading score',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Debug Info:\nUser: ${widget.userId}\nClass: ${widget.classId}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is UserScoreLoaded) {
              return _buildDashboard(context, state.userScore);
            }

            // If transactions are loaded but we don't have the main score yet, show loading
            if (state is TransactionsLoaded ||
                state is StatsLoaded ||
                state is LeaderboardLoaded) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('جاري تحميل نقاطك...'),
                  ],
                ),
              );
            }

            // Initial state or unknown state
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'جاري تحميل البيانات...',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('تحميل النقاط'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'State: ${state.runtimeType}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, UserScoreModel userScore) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Score Card
          UserScoreCard(userScore: userScore),

          const SizedBox(height: 16),

          // Tier Progress
          if (userScore.currentTier != null)
            TierProgressWidget(
              userScore: userScore,
              currentTier: userScore.currentTier!,
            ),

          const SizedBox(height: 16),

          // Quick Actions
          _buildQuickActions(context, userScore),

          const SizedBox(height: 16),

          // Stats Summary
          if (userScore.stats != null) _buildStatsSummary(userScore.stats!),

          const SizedBox(height: 16),

          // Recent Transactions
          _buildRecentTransactionsSection(context),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, UserScoreModel userScore) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إجراءات سريعة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider(
                            create: (context) => ScoringCubit(
                              sl<IScoringRepository>(),
                            ),
                            child: LeaderboardScreen(
                              classId: widget.classId,
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.emoji_events),
                    label: const Text('المتصدرين'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider(
                            create: (context) =>
                                ScoringCubit(sl<IScoringRepository>()),
                            child: TransactionHistoryScreen(
                              userId: widget.userId,
                              classId: widget.classId,
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('السجل'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary(ScoreStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الإحصائيات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('إجمالي النقاط المكتسبة', '+${stats.totalGained}',
                Colors.green),
            const Divider(),
            _buildStatRow(
                'إجمالي النقاط المفقودة', '-${stats.totalLost}', Colors.red),
            const Divider(),
            _buildStatRow(
                'نقاط الحضور', '${stats.attendancePoints}', Colors.blue),
            const Divider(),
            _buildStatRow(
                'النقاط اليدوية', '${stats.manualPoints}', Colors.orange),
            const Divider(),
            _buildStatRow(
                'إجمالي المعاملات', '${stats.transactionCount}', Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'النشاط الأخير',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider(
                          create: (context) =>
                              ScoringCubit(sl<IScoringRepository>()),
                          child: TransactionHistoryScreen(
                            userId: widget.userId,
                            classId: widget.classId,
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('عرض الكل'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RecentTransactionsWidget(
              transactions: _cachedTransactions ?? [],
              isLoading: _cachedTransactions == null,
            ),
          ],
        ),
      ),
    );
  }
}
