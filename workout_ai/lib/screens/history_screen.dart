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
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                const Text('Workout History'),
                const SizedBox(width: AppSpacing.sm),
                if (provider.isDemoMode) const DemoBadge(small: true),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Chip(
                  label: Text('${sessions.length} sessions'),
                  backgroundColor: AppColors.surfaceElevated,
                  labelStyle: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primaryGlow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.fitness_center_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.exercise,
                        style: theme.textTheme.headlineSmall),
                    Text(
                      _formatDate(session.startTime),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              FormScoreRing(score: session.formScore, size: 72),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Stats row
          Row(
            children: [
              _StatChip(
                icon: Icons.repeat_rounded,
                value: '${session.totalReps}',
                label: 'reps',
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatChip(
                icon: Icons.check_circle_rounded,
                value: '${session.goodReps}',
                label: 'good',
                color: AppColors.good,
              ),
              const SizedBox(width: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: session.repetitions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
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
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            '$value $label',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 11,
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
          style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...counts.entries.map((e) {
          final color = _colorFor(e.key);
          final pct = e.value / repetitions.length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    e.key.friendlyName,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: color, fontSize: 11),
                  ),
                ),
                Expanded(
                  child: AnimatedProgressBar(value: pct, color: color, height: 6),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${e.value}x',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '#${rep.repNumber}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              '${(rep.prediction.confidence * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 9,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
