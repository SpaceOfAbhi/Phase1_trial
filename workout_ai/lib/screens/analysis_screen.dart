import 'dart:convert';
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
        if (provider.isBusy) return false;
        if (provider.isAnalysing) {
          final confirmed = await _confirmExit(context);
          if (confirmed) await provider.stopSession();
          return confirmed && !provider.isAnalysing;
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
      toolbarHeight: 80 * MediaQuery.textScalerOf(context).scale(14) / 14,
      bottom: provider.isDemoMode
          ? PreferredSize(
              preferredSize: Size.fromHeight(
                  36 * MediaQuery.textScalerOf(context).scale(14) / 14),
              child: const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: DemoBadge(small: true))),
            )
          : null,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () async {
          if (provider.isBusy) return;
          if (provider.isAnalysing) {
            final confirmed = await _confirmExit(context);
            if (confirmed) {
              await provider.stopSession();
              if (context.mounted && !provider.isAnalysing)
                Navigator.of(context).pop();
            }
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(provider.selectedExercise,
                  style: theme.textTheme.headlineMedium),
            ],
          ),
          if (provider.isAnalysing)
            Row(
              children: [
                PulsingDot(
                  color: provider.isPaused ? AppColors.warning : AppColors.good,
                ),
                const SizedBox(width: 5),
                Expanded(
                    child: Text(
                  provider.isPaused ? 'Paused' : 'Session active',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color:
                        provider.isPaused ? AppColors.warning : AppColors.good,
                  ),
                )),
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
            onPressed: provider.isBusy ? null : provider.pauseResume,
            tooltip: provider.isPaused ? 'Resume' : 'Pause',
          ),
          IconButton(
            icon: const Icon(Icons.stop_rounded),
            color: AppColors.error,
            onPressed: () async {
              if (provider.isBusy) return;
              final confirmed = await _confirmExit(context);
              if (confirmed) {
                await provider.stopSession();
                if (context.mounted && !provider.isAnalysing)
                  Navigator.of(context).pop();
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

    return SingleChildScrollView(
        child: Padding(
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
                ? 'Offline preview: generated signals and mock predictions.'
                : 'Analyze recorded bicep curls with the trained model. Bundled recordings are synthetic; hardware is not connected.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (provider.isDemoMode) ...[
            GradientButton(
              label: 'Start Dataset Demo',
              icon: Icons.science_rounded,
              width: double.infinity,
              onPressed: provider.isBusy ? null : provider.startDemoSession,
            ),
          ] else ...[
            GradientButton(
              label:
                  provider.isBusy ? 'Analyzing…' : 'Analyze Recorded Workout',
              icon: Icons.sensors_rounded,
              width: double.infinity,
              onPressed: provider.isBusy ? null : provider.startSession,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Real model inference · synthetic sample data',
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            TextButton.icon(
              onPressed:
                  provider.isBusy ? null : () => _importRecording(context),
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Analyze your own recording'),
            ),
          ],
          if (provider.error != null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text(provider.error!,
                  style: const TextStyle(color: AppColors.error)),
            ),
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
    ));
  }
}

Future<void> _importRecording(BuildContext context) async {
  final controller = TextEditingController();
  String? error;
  final recording = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
              title: const Text('Import one repetition'),
              content: SizedBox(
                  width: 480,
                  child: SingleChildScrollView(
                      child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                          'Paste a JSON recording with imu and emg arrays. See docs/inference.md for the format. This model requires wrist movement and biceps/triceps signals.'),
                      TextField(
                          controller: controller,
                          minLines: 6,
                          maxLines: 12,
                          decoration: InputDecoration(
                              labelText: 'Recording JSON', errorText: error)),
                    ],
                  ))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () {
                      try {
                        final value = jsonDecode(controller.text);
                        if (value is! Map<String, dynamic> ||
                            value['imu'] is! List ||
                            value['emg'] is! List)
                          throw const FormatException();
                        Navigator.pop(ctx, {
                          ...value,
                          'source': 'user_recording',
                          'expected_label': null
                        });
                      } catch (_) {
                        setState(() => error =
                            'Enter valid JSON with imu and emg arrays.');
                      }
                    },
                    child: const Text('Analyze')),
              ],
            )),
  );
  controller.dispose();
  if (recording != null && context.mounted) {
    final provider = context.read<AnalysisProvider>();
    if (provider.isAnalysing) {
      await provider.nextRep(recording: recording);
    } else {
      await provider.startSession(recording: recording);
    }
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
        if (provider.isBusy) const LinearProgressIndicator(),
        if (provider.error != null)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(provider.error!,
                style: const TextStyle(color: AppColors.error)),
          ),
        Expanded(
            child: SingleChildScrollView(
                child: Column(children: [
          // Prediction card (top)
          _PredictionCard(
            prediction: provider.latestPrediction,
            currentRep: provider.currentSession?.totalReps ?? 0,
          ),
          // Tab bar for signals
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20)),
            child: TabBar(
              controller: tabController,
              labelColor: AppColors.background,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(100)),
              dividerColor: Colors.transparent,
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
          SizedBox(
            height: 280,
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
        ]))),
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
              'Analyzing repetition ${currentRep + 1}…',
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
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rep counter + badge
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              FormClassBadge(label: cls.friendlyName, color: color),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Probabilities
          ProbabilityBars(probabilities: prediction!.probabilities),
          const SizedBox(height: AppSpacing.sm),
          // Description
          Text(prediction!.sourceLabel, style: theme.textTheme.labelSmall),
          if (prediction!.expectedLabel != null)
            Text('Dataset label: ${prediction!.expectedLabel}',
                style: theme.textTheme.labelSmall),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final stats = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  session == null
                      ? 'Starting…'
                      : '${session.totalReps} reps completed',
                  style: theme.textTheme.titleMedium),
              if (session != null && session.totalReps > 0)
                Text(
                    '${session.goodReps} good · ${session.formScore.toStringAsFixed(0)}% form score',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.good)),
            ]);
        final next = provider.currentRep != null && !provider.isPaused
            ? GradientButton(
                label: provider.usesImportedRecording
                    ? 'Import next rep'
                    : 'Next Rep',
                icon: Icons.skip_next_rounded,
                onPressed: provider.isBusy
                    ? null
                    : provider.usesImportedRecording
                        ? () => _importRecording(context)
                        : provider.nextDemoRep,
              )
            : null;
        if (MediaQuery.textScalerOf(context).scale(16) > 21 ||
            provider.usesImportedRecording) {
          return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                stats,
                if (next != null) ...[const SizedBox(height: 12), next]
              ]);
        }
        return Row(children: [
          Expanded(child: stats),
          if (next != null) ...[const SizedBox(width: 12), next]
        ]);
      }),
    );
  }
}
