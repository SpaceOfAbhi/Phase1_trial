import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_models.dart';
import '../services/analysis_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/chart_widgets.dart';
import 'exercise_select_screen.dart';
import 'history_screen.dart';

// ---------------------------------------------------------------------------
// Dashboard Screen
// ---------------------------------------------------------------------------

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _navIndex = 0;

  late final AnimationController _headerCtrl;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut),
    );
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _navIndex,
        children: const [
          _DashboardHome(),
          ExerciseSelectScreen(),
          HistoryScreen(),
        ],
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        backgroundColor: Colors.transparent,
        elevation: 0,
        height: 80,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center_rounded),
            label: 'Workout',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard Home tab
// ---------------------------------------------------------------------------

class _DashboardHome extends StatelessWidget {
  const _DashboardHome();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AnalysisProvider>();
    final history = provider.history;

    final totalSessions = history.length;
    final totalReps = history.fold<int>(0, (s, h) => s + h.totalReps);
    final avgScore = history.isEmpty
        ? 0.0
        : history.fold<double>(0, (s, h) => s + h.formScore) / history.length;

    return CustomScrollView(
      slivers: [
        _DashboardAppBar(isDemoMode: provider.isDemoMode),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _HeroCard(avgScore: avgScore),
              const SizedBox(height: AppSpacing.md),
              _DemoModeToggle(provider: provider),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(
                title: 'Workout Summary',
                icon: Icons.bar_chart_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),
              _SummaryGrid(
                totalSessions: totalSessions,
                totalReps: totalReps,
                avgScore: avgScore,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (history.isNotEmpty) ...[
                const SectionHeader(
                  title: 'Recent Activity',
                  icon: Icons.timeline_rounded,
                ),
                const SizedBox(height: AppSpacing.sm),
                _RecentSessionsList(sessions: history.take(3).toList()),
                const SizedBox(height: AppSpacing.lg),
              ],
              _ModelInfoCard(),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard App Bar
// ---------------------------------------------------------------------------

class _DashboardAppBar extends StatelessWidget {
  const _DashboardAppBar({required this.isDemoMode});

  final bool isDemoMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(children: [
              Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.psychology_alt_rounded,
                      size: 24, color: AppColors.background)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('WorkoutAI', style: theme.textTheme.displayMedium),
                    const SizedBox(height: 4),
                    Text('CNN-LSTM Form Analyser',
                        style: theme.textTheme.bodyMedium),
                    if (isDemoMode) ...[
                      const SizedBox(height: 8),
                      const DemoBadge(small: true)
                    ],
                  ])),
            ]),
          )),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo Mode Toggle
// ---------------------------------------------------------------------------

class _DemoModeToggle extends StatelessWidget {
  const _DemoModeToggle({required this.provider});

  final AnalysisProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      borderColor: provider.isDemoMode ? AppColors.demoChip : AppColors.border,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.demoChipGlow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.science_rounded,
              size: 18,
              color: AppColors.demoChip,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offline UI preview',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  provider.isDemoMode
                      ? 'Generated signals · mock predictions'
                      : 'Trained model · recorded data',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Switch(
            value: provider.isDemoMode,
            onChanged: provider.setDemoMode,
            activeColor: AppColors.demoChip,
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.surfaceHighest,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero Card
// ---------------------------------------------------------------------------

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.avgScore});

  final double avgScore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        LayoutBuilder(builder: (context, constraints) {
          final copy =
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Start Analysis', style: theme.textTheme.displaySmall),
            const SizedBox(height: 8),
            Text(
                'Analyze recorded bicep-curl repetitions with the trained model.',
                style: theme.textTheme.bodyMedium),
          ]);
          if (MediaQuery.textScalerOf(context).scale(16) > 21) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  copy,
                  const SizedBox(height: 16),
                  FormScoreRing(score: avgScore, size: 112)
                ]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(child: copy),
            const SizedBox(width: 16),
            FormScoreRing(score: avgScore, size: 96),
          ]);
        }),
        const SizedBox(height: 20),
        GradientButton(
          label: 'Begin Session',
          icon: Icons.play_arrow_rounded,
          width: double.infinity,
          onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExerciseSelectScreen())),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary Grid
// ---------------------------------------------------------------------------

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.totalSessions,
    required this.totalReps,
    required this.avgScore,
  });

  final int totalSessions;
  final int totalReps;
  final double avgScore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = avgScore >= 75
        ? AppColors.good
        : avgScore >= 50
            ? AppColors.warning
            : AppColors.error;
    return Column(children: [
      LayoutBuilder(builder: (context, constraints) {
        final stacked = MediaQuery.textScalerOf(context).scale(16) > 21;
        final width =
            stacked ? constraints.maxWidth : (constraints.maxWidth - 12) / 2;
        return Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
              width: width,
              child: MetricTile(
                  label: 'Sessions',
                  value: totalSessions.toString(),
                  icon: Icons.calendar_today_rounded,
                  accentColor: AppColors.accent)),
          SizedBox(
              width: width,
              child: MetricTile(
                  label: 'Total Reps',
                  value: totalReps.toString(),
                  icon: Icons.repeat_rounded,
                  accentColor: AppColors.primary)),
        ]);
      }),
      const SizedBox(height: 12),
      GlassCard(
          child: Column(children: [
        Row(children: [
          const Icon(Icons.star_rounded, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
              child: Text('Avg Score', style: theme.textTheme.titleMedium)),
          Text('${avgScore.toStringAsFixed(0)}%',
              style:
                  theme.textTheme.headlineMedium?.copyWith(color: scoreColor)),
        ]),
        const SizedBox(height: 12),
        AnimatedProgressBar(value: avgScore / 100, color: scoreColor),
      ])),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Recent Sessions List
// ---------------------------------------------------------------------------

class _RecentSessionsList extends StatelessWidget {
  const _RecentSessionsList({required this.sessions});

  final List<WorkoutSession> sessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: sessions.map((session) {
        final scoreColor = session.formScore >= 75
            ? AppColors.good
            : session.formScore >= 50
                ? AppColors.warning
                : AppColors.error;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGlow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(session.exercise,
                          style: theme.textTheme.titleMedium),
                      Text(
                        '${session.totalReps} reps · ${session.duration.inMinutes}m ${session.duration.inSeconds % 60}s',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${session.formScore.toStringAsFixed(0)}%',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: scoreColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${session.goodReps}/${session.totalReps} good',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Model Info Card
// ---------------------------------------------------------------------------

class _ModelInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = ModelMetadata.current;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.memory_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Model Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(label: 'Architecture', value: 'CNN-LSTM'),
          _InfoRow(
              label: 'Test Accuracy',
              value: '${(meta.testAccuracy * 100).toStringAsFixed(1)}%'),
          _InfoRow(
              label: 'Sequence Length', value: '${meta.sequenceLength} steps'),
          _InfoRow(
              label: 'Input Features',
              value: '${meta.numFeatures} (6 IMU + 2 EMG)'),
          _InfoRow(label: 'Classes', value: '4 form categories'),
          _InfoRow(label: 'Sampling Rate', value: '${meta.samplingRateHz} Hz'),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warningGlow,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.warning, width: 0.6),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 14, color: AppColors.warning),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Trained on SYNTHETIC data. Results may differ on real sensor data.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.warning,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
