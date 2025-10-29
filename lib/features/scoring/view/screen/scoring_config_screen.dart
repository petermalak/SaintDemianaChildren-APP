import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../viewmodel/config_cubit/config_cubit.dart';
import '../../viewmodel/config_cubit/config_state.dart';
import '../../model/scoring_models.dart';
import '../widget/edit_system_name_dialog.dart';
import '../widget/edit_attendance_points_dialog.dart';
import '../widget/edit_tier_dialog.dart';

class ScoringConfigScreen extends StatefulWidget {
  final String? classId;
  final String? className;

  const ScoringConfigScreen({
    Key? key,
    this.classId,
    this.className,
  }) : super(key: key);

  @override
  State<ScoringConfigScreen> createState() => _ScoringConfigScreenState();
}

class _ScoringConfigScreenState extends State<ScoringConfigScreen> {
  ScoringConfigModel? _config;
  List<ScoringTierModel>? _tiers;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  void _loadConfig() {
    context.read<ConfigCubit>().getConfig(widget.classId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.className != null
              ? 'Configure ${widget.className}'
              : 'Global Scoring Config',
        ),
      ),
      body: BlocListener<ConfigCubit, ConfigState>(
        listener: (context, state) {
          if (state is ConfigError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }

          if (state is ConfigLoaded) {
            setState(() {
              _config = state.config;
              _tiers = state.config.tiers;
            });
          }

          if (state is ConfigUpdated) {
            setState(() {
              _config = state.config;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Configuration updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
            _loadConfig(); // Reload to get latest data
          }

          if (state is TiersLoaded) {
            setState(() {
              _tiers = state.tiers;
            });
          }

          if (state is TierCreated ||
              state is TierUpdated ||
              state is TierDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tier updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
            _loadConfig(); // Reload to get latest data
          }
        },
        child: BlocBuilder<ConfigCubit, ConfigState>(
          builder: (context, state) {
            if (state is ConfigLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_config == null) {
              return const Center(child: Text('No configuration available'));
            }

            return _buildConfigContent();
          },
        ),
      ),
    );
  }

  Widget _buildConfigContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSystemNameSection(),
          const SizedBox(height: 16),
          _buildAttendancePointsSection(),
          const SizedBox(height: 16),
          _buildTiersSection(),
          const SizedBox(height: 16),
          if (widget.classId != null) _buildToggleScoringSection(),
        ],
      ),
    );
  }

  Widget _buildSystemNameSection() {
    return Card(
      child: ListTile(
        title: const Text('System Name'),
        subtitle: Text(_config!.systemName),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () async {
            final result = await showDialog<String>(
              context: context,
              builder: (context) => EditSystemNameDialog(
                currentName: _config!.systemName,
              ),
            );

            if (result != null) {
              context
                  .read<ConfigCubit>()
                  .updateSystemName(widget.classId, result);
            }
          },
        ),
      ),
    );
  }

  Widget _buildAttendancePointsSection() {
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
                  'Attendance Points',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final result = await showDialog<Map<String, int>>(
                      context: context,
                      builder: (context) => EditAttendancePointsDialog(
                        config: _config!,
                      ),
                    );

                    if (result != null) {
                      context.read<ConfigCubit>().updateAttendancePoints(
                            widget.classId,
                            result,
                          );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPointRow('قداس (Mass)', _config!.massPoints),
            _buildPointRow(
                'اجتماع عام (General Meeting)', _config!.generalMeetingPoints),
            _buildPointRow(
                'اجتماع خاص (Special Meeting)', _config!.specialMeetingPoints),
            _buildPointRow('تسبحة (Praise)', _config!.praisePoints),
          ],
        ),
      ),
    );
  }

  Widget _buildPointRow(String label, int points) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          Text(
            '$points points',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTiersSection() {
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
                  'Scoring Tiers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (context) => const EditTierDialog(),
                    );

                    if (result != null) {
                      context
                          .read<ConfigCubit>()
                          .createTier(widget.classId, result);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_tiers != null && _tiers!.isNotEmpty)
              ..._tiers!.map((tier) => _buildTierCard(tier)).toList()
            else
              const Text('No tiers configured'),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard(ScoringTierModel tier) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.star,
          color: _parseColor(tier.color),
        ),
        title: Text(tier.name),
        subtitle: Text(
          '${tier.minPoints} - ${tier.maxPoints ?? '∞'} points',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () async {
                final result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (context) => EditTierDialog(tier: tier),
                );

                if (result != null) {
                  context.read<ConfigCubit>().updateTier(tier.id, result);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Tier'),
                    content:
                        Text('Are you sure you want to delete "${tier.name}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  context.read<ConfigCubit>().deleteTier(tier.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleScoringSection() {
    return Card(
      child: SwitchListTile(
        title: const Text('Enable Scoring'),
        subtitle: const Text('Turn on/off the scoring system for this class'),
        value: _config!.isEnabled,
        onChanged: (value) {
          context.read<ConfigCubit>().toggleScoring(widget.classId!, value);
        },
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
