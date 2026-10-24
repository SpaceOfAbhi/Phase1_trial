import 'package:flutter/material.dart';
import '../models/workout_models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/chart_widgets.dart';

// ---------------------------------------------------------------------------
// RepDetailScreen – shows full details for a single recorded repetition
// ---------------------------------------------------------------------------

class RepDetailScreen extends StatefulWidget {
  const RepDetailScreen({
    super.key,
    required this.rep,
    required this.sessionExercise,
  });

  final WorkoutRepetition rep;
  final String sessionExercise;

  @override
  State<RepDetailScreen> createState() => _RepDetailScreenState();
}

class _RepDetailScreenState extends State<RepDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color get _predictionColor {
    switch (widget.rep.prediction.predictedClass) {
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
    final theme = Theme.of(context);
    final rep = widget.rep;
    final pred = rep.prediction;
    final color = _predictionColor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight:
            80 + (MediaQuery.textScalerOf(context).scale(13) - 13) * 8,
        backgroundColor: AppColors.background,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.sessionExercise} – Rep #${rep.repNumber}',
              style: theme.textTheme.headlineMedium,
            ),
            Row(
              children: [
                if (pred.isDemo) const DemoBadge(small: true),
                if (pred.isDemo) const SizedBox(width: 6),
                Text(
                  _formatTime(pred.timestamp),
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Prediction Hero Banner ---
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CLASSIFICATION RESULT',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(letterSpacing: 1.2),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          FormClassBadge(
                            label: pred.predictedClass.friendlyName,
                            color: color,
                            large: true,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            pred.predictedClass.description,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Confidence circle
                      _ConfidenceCircle(
                        value: pred.confidence,
                        color: color,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(pred.sourceLabel, style: theme.textTheme.bodyMedium),
                  if (pred.expectedLabel != null)
                    Text('Dataset label: ${pred.expectedLabel}',
                        style: theme.textTheme.bodyMedium),
                  if (pred.isDemo) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.demoChipGlow,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.science_rounded,
                              size: 13, color: AppColors.demoChip),
                          const SizedBox(width: 5),
                          Flexible(
                              child: Text(
                            'MOCK PREDICTION – Dataset Demo Mode. '
                            'Not real CNN-LSTM inference.',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.demoChip,
                              fontSize: 13,
                            ),
                          )),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // --- Probability breakdown ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Class Probabilities',
                    icon: Icons.bar_chart_rounded,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GlassCard(
                    child: ProbabilityBars(probabilities: pred.probabilities),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // --- Signal charts ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: const SectionHeader(
                title: 'Sensor Signals',
                icon: Icons.sensors_rounded,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20)),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelPadding: const EdgeInsets.symmetric(horizontal: 20),
                controller: _tabController,
                labelColor: AppColors.background,
                unselectedLabelColor: AppColors.textMuted,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(100)),
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Accelerometer'),
                  Tab(text: 'Gyroscope'),
                  Tab(text: 'EMG'),
                ],
              ),
            ),
            SizedBox(
              height:
                  360 + (MediaQuery.textScalerOf(context).scale(13) - 13) * 12,
              child: TabBarView(
                controller: _tabController,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: AccelerometerChart(samples: rep.imuSamples),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: GyroscopeChart(samples: rep.imuSamples),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: EmgChart(samples: rep.emgSamples),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // --- Raw Stats ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Signal Statistics',
                    icon: Icons.analytics_rounded,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (rep.imuSamples.isNotEmpty)
                    _SignalStatsCard(
                      title: 'IMU (Accelerometer)',
                      samples: rep.imuSamples,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

// ---------------------------------------------------------------------------
// Confidence Circle
// ---------------------------------------------------------------------------

class _ConfidenceCircle extends StatelessWidget {
  const _ConfidenceCircle({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 104 * MediaQuery.textScalerOf(context).scale(13) / 13,
      height: 104 * MediaQuery.textScalerOf(context).scale(13) / 13,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${(value * 100).toStringAsFixed(0)}%',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          Text(
            'confidence',
            style: theme.textTheme.labelSmall?.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Signal Stats Card
// ---------------------------------------------------------------------------

class _SignalStatsCard extends StatelessWidget {
  const _SignalStatsCard({required this.title, required this.samples});

  final String title;
  final List<ImuSample> samples;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final axes = ['accel_x', 'accel_y', 'accel_z'];
    final values = [
      samples.map((s) => s.accelerometerX).toList(),
      samples.map((s) => s.accelerometerY).toList(),
      samples.map((s) => s.accelerometerZ).toList(),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...List.generate(3, (i) {
            final v = values[i];
            if (v.isEmpty) return const SizedBox.shrink();
            final stats = [
              v.reduce((a, b) => a < b ? a : b),
              v.reduce((a, b) => a > b ? a : b),
              v.fold(0.0, (a, b) => a + b) / v.length,
            ];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(axes[i].toUpperCase(),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: AppColors.primary)),
                    const SizedBox(height: 12),
                    Row(
                        children: List.generate(
                            3,
                            (j) => Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(['Min', 'Max', 'Mean'][j],
                                            style: theme.textTheme.labelSmall),
                                        const SizedBox(height: 6),
                                        Text(stats[j].toStringAsFixed(2),
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                    color:
                                                        AppColors.textPrimary)),
                                      ]),
                                ))),
                    if (i < 2)
                      const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Divider(height: 1)),
                  ]),
            );
          }),
        ],
      ),
    );
  }
}
