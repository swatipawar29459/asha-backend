
class Prediction {
  final int currentDay;
  final String phaseLabel;
  final int confidence;
  final String nextPeriodLabel;
  final String fertileWindowLabel;
  final double cycleProgress;
  final Map<String, double> factorWeights;
  final bool pcosRisk;
  final int avgCycleLength;
  final int avgPeriodLength;
  final List<int> cycleLengthHistory;

  Prediction({
    required this.currentDay, required this.phaseLabel, required this.confidence,
    required this.nextPeriodLabel, required this.fertileWindowLabel, required this.cycleProgress,
    required this.factorWeights, required this.pcosRisk, required this.avgCycleLength,
    required this.avgPeriodLength, required this.cycleLengthHistory,
  });

  factory Prediction.fromJson(Map<String, dynamic> j) => Prediction(
        currentDay: j['current_day'] ?? 1,
        phaseLabel: j['phase_label'] ?? '',
        confidence: j['confidence'] ?? 0,
        nextPeriodLabel: j['next_period_label'] ?? '',
        fertileWindowLabel: j['fertile_window_label'] ?? '',
        cycleProgress: (j['cycle_progress'] as num?)?.toDouble() ?? 0.3,
        factorWeights: Map<String, double>.from(j['factor_weights'] ?? {}),
        pcosRisk: j['pcos_risk'] ?? false,
        avgCycleLength: j['avg_cycle_length'] ?? 29,
        avgPeriodLength: j['avg_period_length'] ?? 5,
        cycleLengthHistory: List<int>.from(j['cycle_length_history'] ?? [28, 30, 27, 31, 29]),
      );
}