import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/analysis_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'analysis_screen.dart';

// ---------------------------------------------------------------------------
// ExerciseSelectScreen
// ---------------------------------------------------------------------------

/// Workout selection screen with exercise cards.
/// Currently only Bicep Curl is supported (matching the trained model).
class ExerciseSelectScreen extends StatelessWidget {
  const ExerciseSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<AnalysisProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Select Exercise'),
        backgroundColor: AppColors.background,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Disclaimer banner
                _DemoBanner(isDemoMode: provider.isDemoMode),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Choose Exercise',
                  style: theme.textTheme.displayMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'The CNN-LSTM model is trained to classify bicep-curl form.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                // Bicep Curl card (active)
                _ExerciseCard(
                  name: 'Bicep Curl',
                  muscleGroup: 'Biceps · Forearms',
                  description:
                      'Classifies into GOOD, PARTIAL_ROM, EXCESSIVE_SWING, EXCESSIVE_ELBOW_MOVEMENT.',
                  icon: Icons.fitness_center_rounded,
                  accentColor: AppColors.primary,
                  isAvailable: true,
                  onTap: () {
                    provider.selectExercise('Bicep Curl');
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AnalysisScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // Placeholder exercises (coming soon)
                _ExerciseCard(
                  name: 'Squat',
                  muscleGroup: 'Quads · Glutes · Hamstrings',
                  description: 'Not supported by the supplied model.',
                  icon: Icons.accessibility_new_rounded,
                  accentColor: AppColors.textMuted,
                  isAvailable: false,
                ),
                const SizedBox(height: AppSpacing.md),
                _ExerciseCard(
                  name: 'Shoulder Press',
                  muscleGroup: 'Deltoids · Triceps',
                  description: 'Not supported by the supplied model.',
                  icon: Icons.sports_gymnastics_rounded,
                  accentColor: AppColors.textMuted,
                  isAvailable: false,
                ),
                const SizedBox(height: AppSpacing.md),
                _ExerciseCard(
                  name: 'Deadlift',
                  muscleGroup: 'Back · Glutes · Hamstrings',
                  description: 'Not supported by the supplied model.',
                  icon: Icons.sports_mma_rounded,
                  accentColor: AppColors.textMuted,
                  isAvailable: false,
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo Mode Banner
// ---------------------------------------------------------------------------

class _DemoBanner extends StatelessWidget {
  const _DemoBanner({required this.isDemoMode});

  final bool isDemoMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!isDemoMode) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.warningGlow,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.warning, width: 0.8),
        ),
        child: Row(
          children: [
            const Icon(Icons.sensors_off_rounded,
                color: AppColors.warning, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Recorded analysis uses the trained model. Bundled data is synthetic. '
                'Shoe hardware is not connected.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.warning,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.demoChipGlow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.demoChip, width: 0.8),
      ),
      child: Row(
        children: [
          const Icon(Icons.science_rounded,
              color: AppColors.demoChip, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Offline preview: generated signals will be shown. '
              'Predictions are MOCK – not real CNN-LSTM inference.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.demoChip,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise Card
// ---------------------------------------------------------------------------

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.name,
    required this.muscleGroup,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.isAvailable,
    this.onTap,
  });

  final String name;
  final String muscleGroup;
  final String description;
  final IconData icon;
  final Color accentColor;
  final bool isAvailable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      onTap: isAvailable ? onTap : null,
      borderColor:
          isAvailable ? accentColor.withValues(alpha: 0.4) : AppColors.border,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: accentColor.withValues(alpha: 0.3), width: 0.8),
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                        child: Text(
                      name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: isAvailable
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    )),
                    const SizedBox(width: AppSpacing.sm),
                    if (!isAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'SOON',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  muscleGroup,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: accentColor,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          if (isAvailable) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right_rounded, color: accentColor, size: 24),
          ],
        ],
      ),
    );
  }
}
