import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/workout_models.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

// ---------------------------------------------------------------------------
// SignalChart – renders a time-series signal (IMU or EMG)
// ---------------------------------------------------------------------------

/// Renders up to three signal channels on a single fl_chart line chart.
/// Used for accelerometer (X/Y/Z), gyroscope (X/Y/Z) and EMG (biceps/triceps).
class SignalChart extends StatelessWidget {
  const SignalChart({
    super.key,
    required this.title,
    required this.series,
    required this.colors,
    required this.legendLabels,
    this.height = 180,
    this.minY,
    this.maxY,
  });

  final String title;
  final List<List<double>> series; // list of value arrays per channel
  final List<Color> colors;
  final List<String> legendLabels;
  final double height;
  final double? minY;
  final double? maxY;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelSize = MediaQuery.textScalerOf(context).scale(13);

    final maxLen =
        series.fold<int>(0, (prev, s) => s.length > prev ? s.length : prev);

    if (maxLen == 0) {
      return _emptyPlaceholder(theme);
    }

    // Build LineChartBarData for each channel
    final lineBarsData = <LineChartBarData>[];
    for (int ci = 0; ci < series.length; ci++) {
      final vals = series[ci];
      if (vals.isEmpty) continue;

      final spots = <FlSpot>[];
      for (int i = 0; i < vals.length; i++) {
        spots.add(FlSpot(i.toDouble(), vals[i]));
      }

      lineBarsData.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.25,
          color: colors[ci % colors.length],
          barWidth: 2.4,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: ci == 0,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colors[ci % colors.length].withValues(alpha: 0.15),
                Colors.transparent,
              ],
            ),
          ),
        ),
      );
    }

    // Compute y-axis bounds
    double computedMin = minY ?? double.infinity;
    double computedMax = maxY ?? double.negativeInfinity;
    if (minY == null || maxY == null) {
      for (final s in series) {
        for (final v in s) {
          if (minY == null && v < computedMin) computedMin = v;
          if (maxY == null && v > computedMax) computedMax = v;
        }
      }
      final range = computedMax - computedMin;
      final pad = range == 0 ? 1.0 : range * 0.15;
      if (minY == null) computedMin -= pad;
      if (maxY == null) computedMax += pad;
    }

    return GlassCard(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + legend
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: List.generate(
                legendLabels.length,
                (i) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors[i % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      legendLabels[i],
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: height + (labelSize - 13) * 4,
          child: LineChart(
            LineChartData(
              lineBarsData: lineBarsData,
              minX: 0,
              maxX: (maxLen > 1 ? maxLen - 1 : 1).toDouble(),
              minY: computedMin,
              maxY: computedMax,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (computedMax - computedMin) / 3,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.border.withValues(alpha: 0.4),
                  strokeWidth: 0.7,
                  dashArray: [3, 4],
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: labelSize * 4.5,
                    interval: (computedMax - computedMin) / 3,
                    getTitlesWidget: (val, meta) {
                      if (val == meta.min || val == meta.max)
                        return const SizedBox.shrink();
                      return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 12,
                          child: Text(
                            val.toStringAsFixed(1),
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ));
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: labelSize * 2.5,
                    interval:
                        ((maxLen - 1) / 2).ceil().clamp(1, maxLen).toDouble(),
                    getTitlesWidget: (val, meta) {
                      return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 10,
                          fitInside: SideTitleFitInsideData.fromTitleMeta(meta,
                              distanceFromEdge: 0),
                          child: Text(
                            val.toInt().toString(),
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ));
                    },
                  ),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipColor: (_) => AppColors.surfaceHighest,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final label =
                          legendLabels[spot.barIndex % legendLabels.length];
                      return LineTooltipItem(
                        '$label: ${spot.y.toStringAsFixed(2)}',
                        TextStyle(
                          color: colors[spot.barIndex % colors.length],
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
            duration: const Duration(milliseconds: 50),
          ),
        ),
      ],
    ));
  }

  Widget _emptyPlaceholder(ThemeData theme) {
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.ssid_chart_rounded,
                size: 28, color: AppColors.textMuted),
            const SizedBox(height: 6),
            Text(
              'Waiting for $title data…',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// IMU charts helpers
// ---------------------------------------------------------------------------

class AccelerometerChart extends StatelessWidget {
  const AccelerometerChart({super.key, required this.samples});

  final List<ImuSample> samples;

  @override
  Widget build(BuildContext context) {
    return SignalChart(
      title: 'Accelerometer',
      series: [
        samples.map((s) => s.accelerometerX).toList(),
        samples.map((s) => s.accelerometerY).toList(),
        samples.map((s) => s.accelerometerZ).toList(),
      ],
      colors: const [AppColors.error, AppColors.good, AppColors.info],
      legendLabels: const ['X', 'Y', 'Z'],
    );
  }
}

class GyroscopeChart extends StatelessWidget {
  const GyroscopeChart({super.key, required this.samples});

  final List<ImuSample> samples;

  @override
  Widget build(BuildContext context) {
    return SignalChart(
      title: 'Gyroscope',
      series: [
        samples.map((s) => s.gyroscopeX).toList(),
        samples.map((s) => s.gyroscopeY).toList(),
        samples.map((s) => s.gyroscopeZ).toList(),
      ],
      colors: const [Color(0xFFFF6B6B), Color(0xFFFFE66D), Color(0xFF4ECDC4)],
      legendLabels: const ['X', 'Y', 'Z'],
    );
  }
}

class EmgChart extends StatelessWidget {
  const EmgChart({super.key, required this.samples});

  final List<EmgSample> samples;

  @override
  Widget build(BuildContext context) {
    return SignalChart(
      title: 'EMG Activation',
      series: [
        samples.map((s) => s.bicepsRms).toList(),
        samples.map((s) => s.tricepsRms).toList(),
      ],
      colors: const [AppColors.primary, AppColors.warning],
      legendLabels: const ['Biceps RMS', 'Triceps RMS'],
      minY: 0,
    );
  }
}

// ---------------------------------------------------------------------------
// FormScoreRing – circular donut showing overall session form score
// ---------------------------------------------------------------------------

class FormScoreRing extends StatelessWidget {
  const FormScoreRing({
    super.key,
    required this.score,
    this.size = 120,
  });

  final double score; // 0..100
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = score / 100.0;
    final color = score >= 75
        ? AppColors.good
        : score >= 50
            ? AppColors.warning
            : AppColors.error;

    return Semantics(
      label: 'Form Score',
      value: '${score.toStringAsFixed(0)}%',
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                    child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircularProgressIndicator(
                      value: pct.clamp(0, 1),
                      strokeWidth: size * 0.12,
                      strokeCap: StrokeCap.round,
                      backgroundColor: color.withValues(alpha: 0.16),
                      color: color),
                )),
                Text('${score.toStringAsFixed(0)}%',
                    style: theme.textTheme.headlineMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: size > 100 ? 26 : 16,
                        fontWeight: FontWeight.w600)),
              ],
            )),
        const SizedBox(height: 8),
        Text('Form Score', style: theme.textTheme.labelSmall),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// ProbabilityBars – shows softmax output for all four form classes
// ---------------------------------------------------------------------------

class ProbabilityBars extends StatelessWidget {
  const ProbabilityBars({super.key, required this.probabilities});

  /// Length-4 list matching label encoder order:
  /// 0=EXCESSIVE_ELBOW_MOVEMENT, 1=EXCESSIVE_SWING, 2=GOOD, 3=PARTIAL_ROM
  final List<double> probabilities;

  static const _labels = [
    'Elbow Drift',
    'Excessive Swing',
    'Good Form',
    'Partial ROM',
  ];

  static const _colors = [
    AppColors.error,
    AppColors.warning,
    AppColors.good,
    AppColors.info,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: List.generate(4, (i) {
        final prob = i < probabilities.length ? probabilities[i] : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              Row(children: [
                Expanded(
                  child: Text(
                    _labels[i],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(prob * 100).toStringAsFixed(1)}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _colors[i],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              AnimatedProgressBar(value: prob, color: _colors[i], height: 8),
            ],
          ),
        );
      }),
    );
  }
}
