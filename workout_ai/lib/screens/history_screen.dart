import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_models.dart';
import '../services/analysis_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/chart_widgets.dart';
import 'rep_detail_screen.dart';

// ---------------------------------------------------------------------------
// HistoryScreen
// ---------------------------------------------------------------------------

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AnalysisProvider>();
    final sessions = provider.history;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
              child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Workout History',
                        style: theme.textTheme.displaySmall),
                    const SizedBox(height: 12),
                    Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Chip(label: Text('${sessions.length} sessions')),
                          if (provider.isDemoMode) const DemoBadge(small: true),
                        ]),
                  ]),
            ),
          )),
          if (sessions.isEmpty)
            SliverFillRemaining(
              child: EmptyStateWidget(
                icon: Icons.history_rounded,
                title: 'No sessions yet',
                subtitle:
                    'Complete a workout session to see your history here.',
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final session = sessions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _SessionCard(session: session),
                    );
                  },
                  childCount: sessions.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Session Card
// ---------------------------------------------------------------------------

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = session.formScore >= 75
        ? AppColors.good
        : session.formScore >= 50
            ? AppColors.warning
            : AppColors.error;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.exercise,
                        style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(session.startTime),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              FormScoreRing(score: session.formScore, size: 80),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Stats row
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatChip(
                icon: Icons.repeat_rounded,
                value: '${session.totalReps}',
                label: 'reps',
                color: AppColors.primary,
              ),
              _StatChip(
                icon: Icons.check_circle_rounded,
                value: '${session.goodReps}',
                label: 'good',
                color: AppColors.good,
              ),
              _StatChip(
                icon: Icons.timer_rounded,
                value: _formatDuration(session.duration),
                label: 'time',
                color: AppColors.info,
              ),
            ],
          ),
          // Form class breakdown
          if (session.repetitions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            _FormBreakdown(repetitions: session.repetitions),
          ],
          // Rep list
          if (session.repetitions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(session.repetitions.length, (i) {
                final rep = session.repetitions[i];
                return _RepChip(
                  rep: rep,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RepDetailScreen(
                        rep: rep,
                        sessionExercise: session.exercise,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} · $hour:$min';
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes == 0) return '${d.inSeconds}s';
    return '${d.inMinutes}m ${d.inSeconds % 60}s';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            '$value $label',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormBreakdown extends StatelessWidget {
  const _FormBreakdown({required this.repetitions});

  final List<WorkoutRepetition> repetitions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Count occurrences of each class
    final counts = <FormClass, int>{};
    for (final rep in repetitions) {
      final cls = rep.prediction.predictedClass;
      counts[cls] = (counts[cls] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FORM BREAKDOWN',
          style: theme.textTheme.labelSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        ...counts.entries.map((e) {
          final color = _colorFor(e.key);
          final pct = e.value / repetitions.length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                Row(children: [
                  Expanded(
                      child: Text(
                    e.key.friendlyName,
                    style: theme.textTheme.bodyMedium,
                  )),
                  const SizedBox(width: 12),
                  Text(
                    '${e.value}x',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: color, fontWeight: FontWeight.w700),
                  ),
                ]),
                const SizedBox(height: 8),
                AnimatedProgressBar(value: pct, color: color, height: 8),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _colorFor(FormClass cls) {
    switch (cls) {
      case FormClass.good:
        return AppColors.good;
      case FormClass.partialRom:
        return AppColors.info;
      case FormClass.excessiveSwing:
        return AppColors.warning;
      case FormClass.excessiveElbowMovement:
        return AppColors.error;
    }
  }
}

class _RepChip extends StatelessWidget {
  const _RepChip({required this.rep, required this.onTap});

  final WorkoutRepetition rep;
  final VoidCallback onTap;

  Color _color() {
    switch (rep.prediction.predictedClass) {
      case FormClass.good:
        return AppColors.good;
      case FormClass.partialRom:
        return AppColors.info;
      case FormClass.excessiveSwing:
        return AppColors.warning;
      case FormClass.excessiveElbowMovement:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(72, 64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '#${rep.repNumber}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(rep.prediction.confidence * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
