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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
      physics: const BouncingScrollPhysics(),
      slivers: [
        _DashboardAppBar(isDemoMode: provider.isDemoMode),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _DemoModeToggle(provider: provider),
              const SizedBox(height: AppSpacing.lg),
              _HeroCard(avgScore: avgScore),
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
              const SizedBox(height: 100),
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
    return SliverAppBar(
      expandedHeight: 110,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(
          left: AppSpacing.md,
          bottom: AppSpacing.md,
        ),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.psychology_alt_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WorkoutAI',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'CNN-LSTM Form Analyser',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            if (isDemoMode) const DemoBadge(small: true),
          ],
        ),
      ),
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
                  'Dataset Demo Mode',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  provider.isDemoMode
                      ? 'Using synthetic dataset – not real sensor data'
                      : 'Live sensor mode – connect FastAPI backend',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.35),
            AppColors.primary.withValues(alpha: 0.18),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start Analysis',
                  style: theme.textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'CNN-LSTM model classifies your bicep-curl repetitions in real time.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                GradientButton(
                  label: 'Begin Session',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () {
                    // Navigate to exercise select (nav index 1)
                    // Handled via parent widget's nav state
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ExerciseSelectScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          FormScoreRing(score: avgScore, size: 110),
        ],
      ),
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
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 0.95,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        MetricTile(
          label: 'Sessions',
          value: totalSessions.toString(),
          icon: Icons.calendar_today_rounded,
          accentColor: AppColors.accent,
        ),
        MetricTile(
          label: 'Total Reps',
          value: totalReps.toString(),
          icon: Icons.repeat_rounded,
          accentColor: AppColors.primary,
        ),
        MetricTile(
          label: 'Avg Score',
          value: avgScore.toStringAsFixed(0),
          unit: '%',
          icon: Icons.star_rounded,
          accentColor: avgScore >= 75
              ? AppColors.good
              : avgScore >= 50
                  ? AppColors.warning
                  : AppColors.error,
        ),
      ],
    );
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
          _InfoRow(label: 'Input Features', value: '${meta.numFeatures} (6 IMU + 2 EMG)'),
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
