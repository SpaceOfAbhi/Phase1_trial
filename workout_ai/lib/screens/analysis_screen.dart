import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_models.dart';
import '../services/analysis_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/chart_widgets.dart';

// ---------------------------------------------------------------------------
// AnalysisScreen – the main form-analysis / rep recording screen
// ---------------------------------------------------------------------------

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with TickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        if (provider.isAnalysing) {
          final confirmed = await _confirmExit(context);
          if (confirmed) provider.stopSession();
          return confirmed;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context, provider, theme),
        body: provider.isAnalysing
            ? _AnalysisActiveView(tabController: _tabController)
            : _AnalysisIdleView(),
      ),
    );
  }

  AppBar _buildAppBar(
      BuildContext context, AnalysisProvider provider, ThemeData theme) {
    return AppBar(
      backgroundColor: AppColors.background,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () async {
          if (provider.isAnalysing) {
            final confirmed = await _confirmExit(context);
            if (confirmed) {
              provider.stopSession();
              if (context.mounted) Navigator.of(context).pop();
            }
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(provider.selectedExercise,
                  style: theme.textTheme.headlineMedium),
              if (provider.isDemoMode) ...[
                const SizedBox(width: AppSpacing.sm),
                const DemoBadge(small: true),
              ],
            ],
          ),
          if (provider.isAnalysing)
            Row(
              children: [
                PulsingDot(
                  color: provider.isPaused
                      ? AppColors.warning
                      : AppColors.good,
                ),
                const SizedBox(width: 5),
                Text(
                  provider.isPaused ? 'Paused' : 'Recording',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: provider.isPaused
                        ? AppColors.warning
                        : AppColors.good,
                  ),
                ),
              ],
            ),
        ],
      ),
      actions: [
        if (provider.isAnalysing) ...[
          IconButton(
            icon: Icon(provider.isPaused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded),
            color: AppColors.warning,
            onPressed: provider.pauseResume,
            tooltip: provider.isPaused ? 'Resume' : 'Pause',
          ),
          IconButton(
            icon: const Icon(Icons.stop_rounded),
            color: AppColors.error,
            onPressed: () async {
              final confirmed = await _confirmExit(context);
              if (confirmed) {
                provider.stopSession();
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            tooltip: 'Stop session',
          ),
        ],
      ],
    );
  }

  Future<bool> _confirmExit(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              side: const BorderSide(color: AppColors.border),
            ),
            title: const Text('End Session?'),
            content:
                const Text('The current session will be saved to history.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('End Session'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// ---------------------------------------------------------------------------
// Idle View – before session starts
// ---------------------------------------------------------------------------

class _AnalysisIdleView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.read<AnalysisProvider>();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hero icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryGlow, AppColors.accentGlow],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
            ),
            child: const Icon(
              Icons.play_circle_outline_rounded,
              size: 52,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Ready to Analyse', style: theme.textTheme.displayMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            provider.isDemoMode
                ? 'Demo mode: synthetic sensor data from the training dataset will be replayed. Predictions are MOCK.'
                : 'Connect your IMU + EMG sensors and start the FastAPI backend before recording.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (provider.isDemoMode) ...[
            GradientButton(
              label: 'Start Dataset Demo',
              icon: Icons.science_rounded,
              width: double.infinity,
              gradient: const LinearGradient(
                colors: [AppColors.demoChip, AppColors.accent],
              ),
              color: AppColors.demoChip,
              onPressed: provider.startDemoSession,
            ),
          ] else ...[
            GradientButton(
              label: 'Start Live Session',
              icon: Icons.sensors_rounded,
              width: double.infinity,
              onPressed: null, // disabled until backend connected
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Requires FastAPI backend connection',
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          // Model info pills
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: const [
              _InfoPill(label: 'CNN-LSTM', icon: Icons.memory_rounded),
              _InfoPill(label: '256 steps', icon: Icons.timeline_rounded),
              _InfoPill(label: '8 features', icon: Icons.sensors_rounded),
              _InfoPill(label: '4 classes', icon: Icons.category_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Active Session View
// ---------------------------------------------------------------------------

class _AnalysisActiveView extends StatelessWidget {
  const _AnalysisActiveView({required this.tabController});

  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();

    return Column(
      children: [
        // Prediction card (top)
        _PredictionCard(
          prediction: provider.latestPrediction,
          currentRep: provider.currentSession?.totalReps ?? 0,
        ),
        // Tab bar for signals
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Accelerometer'),
              Tab(text: 'Gyroscope'),
              Tab(text: 'EMG'),
            ],
          ),
        ),
        // Signal charts
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              _SignalTab(
                child: AccelerometerChart(samples: provider.liveImu),
              ),
              _SignalTab(
                child: GyroscopeChart(samples: provider.liveImu),
              ),
              _SignalTab(
                child: EmgChart(samples: provider.liveEmg),
              ),
            ],
          ),
        ),
        // Bottom action bar
        _SessionControls(provider: provider),
      ],
    );
  }
}

class _SignalTab extends StatelessWidget {
  const _SignalTab({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Prediction Card
// ---------------------------------------------------------------------------

class _PredictionCard extends StatelessWidget {
  const _PredictionCard({
    required this.prediction,
    required this.currentRep,
  });

  final PredictionResult? prediction;
  final int currentRep;

  Color _colorFor(FormClass cls) {
    switch (cls) {
      case FormClass.good:
        return AppColors.good;
      case FormClass.partialRom:
        return AppColors.info;
      case FormClass.excessiveSwing:
      case FormClass.excessiveElbowMovement:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (prediction == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        color: AppColors.surface,
        child: Row(
          children: [
            const SizedBox(width: 6),
            PulsingDot(color: AppColors.primary, size: 8),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Collecting data for repetition $currentRep…',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    final cls = prediction!.predictedClass;
    final color = _colorFor(cls);
    final confidence = prediction!.confidence;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(color: color.withValues(alpha: 0.4), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rep counter + badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'REP $currentRep',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (prediction!.isDemo) const DemoBadge(small: true),
              const Spacer(),
              FormClassBadge(label: cls.friendlyName, color: color),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Probabilities
          ProbabilityBars(probabilities: prediction!.probabilities),
          const SizedBox(height: AppSpacing.sm),
          // Description
          Text(
            cls.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Session Controls Bar
// ---------------------------------------------------------------------------

class _SessionControls extends StatelessWidget {
  const _SessionControls({required this.provider});

  final AnalysisProvider provider;

  @override
  Widget build(BuildContext context) {
    final session = provider.currentSession;
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
            top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          // Session stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session == null
                      ? 'Starting…'
                      : '${session.totalReps} reps completed',
                  style: theme.textTheme.titleMedium,
                ),
                if (session != null && session.totalReps > 0)
                  Text(
                    '${session.goodReps} good · ${session.formScore.toStringAsFixed(0)}% form score',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.good,
                    ),
                  ),
              ],
            ),
          ),
          // Next Rep button
          if (provider.currentRep != null && !provider.isPaused)
            GradientButton(
              label: 'Next Rep',
              icon: Icons.skip_next_rounded,
              onPressed: provider.nextDemoRep,
            ),
        ],
      ),
    );
  }
}


