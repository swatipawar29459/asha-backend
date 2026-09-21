class Prediction {
  final int currentDay;
  final String phaseLabel;
  final int confidence;
  final String nextPeriodLabel;
  final String fertileWindowLabel;
  final double cycleProgress;
  final Map<String, double> factorWeights;

  final String pcosRisk;

  final int avgCycleLength;
  final int avgPeriodLength;
  final List<int> cycleLengthHistory;

  Prediction({
    required this.currentDay,
    required this.phaseLabel,
    required this.confidence,
    required this.nextPeriodLabel,
    required this.fertileWindowLabel,
    required this.cycleProgress,
    required this.factorWeights,
    required this.pcosRisk,
    required this.avgCycleLength,
    required this.avgPeriodLength,
    required this.cycleLengthHistory,
  });

  factory Prediction.fromJson(
    Map<String, dynamic> j,
  ) {
    return Prediction(
      currentDay:
          (j['current_day'] as num?)?.toInt() ?? 1,

      phaseLabel:
          j['phase_label']?.toString() ?? '',

      confidence:
          (j['confidence'] as num?)?.toInt() ?? 0,

      nextPeriodLabel:
          j['next_period']?.toString() ??
          j['next_period_label']?.toString() ??
          '',

      fertileWindowLabel:
          j['fertile_window']?.toString() ??
          j['fertile_window_label']?.toString() ??
          '',

      cycleProgress:
          (j['cycle_progress'] as num?)?.toDouble() ??
          0.3,

      factorWeights:
          Map<String, double>.from(
        j['factor_weights'] ?? {},
      ),

      pcosRisk:
          j['pcos_risk']?.toString() ?? 'Low',

      avgCycleLength:
          (j['avg_cycle_length'] as num?)?.toInt() ?? 29,

      avgPeriodLength:
          (j['avg_period_length'] as num?)?.toInt() ?? 5,

      cycleLengthHistory:
          List<int>.from(
        j['cycle_length_history'] ??
            [28, 30, 27, 31, 29],
      ),
    );
  }
}