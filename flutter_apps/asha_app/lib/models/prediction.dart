class Prediction {
  final int currentDay;
  final String phaseLabel;

  final String nextPeriodLabel;
  final String fertileWindowLabel;

  final double cycleProgress;

  // Actual Decision Tree feature importance.
  final Map<String, double> factorWeights;

  // This is the user's reported PCOS status.
  // It is NOT a PCOS prediction.
  final String pcosRisk;

  final int avgCycleLength;
  final int avgPeriodLength;

  final List<int> cycleLengthHistory;

  final int predictedCycleLength;

  Prediction({
    required this.currentDay,
    required this.phaseLabel,
    required this.nextPeriodLabel,
    required this.fertileWindowLabel,
    required this.cycleProgress,
    required this.factorWeights,
    required this.pcosRisk,
    required this.avgCycleLength,
    required this.avgPeriodLength,
    required this.cycleLengthHistory,
    required this.predictedCycleLength,
  });

  factory Prediction.fromJson(
    Map<String, dynamic> j,
  ) {
    // ==========================================================
    // ACTUAL MODEL FEATURE IMPORTANCE
    // ==========================================================

    final rawFactors = j['factor_weights'];

    final Map<String, double> factors = {};

    if (rawFactors is Map) {
      rawFactors.forEach(
        (key, value) {
          if (value is num) {
            factors[key.toString()] = value.toDouble();
          }
        },
      );
    }

    // ==========================================================
    // CYCLE HISTORY
    // ==========================================================

    final historyRaw =
        j['cycle_length_history'];

    final List<int> history = [];

    if (historyRaw is List) {
      for (final item in historyRaw) {
        if (item is num) {
          history.add(
            item.toInt(),
          );
        }
      }
    }

    // ==========================================================
    // AVERAGE / CURRENT CYCLE LENGTH
    // ==========================================================

    final avgCycle =
        (j['avg_cycle_length'] as num?)
                ?.toInt() ??
            28;

    if (history.isEmpty) {
      history.add(avgCycle);
    }

    // ==========================================================
    // PREDICTED CYCLE LENGTH
    // ==========================================================

    final predictedCycle =
        (j['predicted_cycle_length'] as num?)
                ?.toInt() ??
            avgCycle;

    // ==========================================================
    // PCOS STATUS
    // ==========================================================

    String pcosStatus =
        j['pcos_risk']?.toString() ??
            'No PCOS reported';

    // Backward compatibility:
    // If an old backend sends true/false,
    // convert it safely to readable text.

    if (pcosStatus.toLowerCase() == 'true') {
      pcosStatus = 'Reported PCOS';
    }

    if (pcosStatus.toLowerCase() == 'false') {
      pcosStatus = 'No PCOS reported';
    }

    // ==========================================================
    // RETURN
    // ==========================================================

    return Prediction(
      currentDay:
          (j['current_day'] as num?)
                  ?.toInt() ??
              1,

      phaseLabel:
          j['phase_label']
                  ?.toString() ??
              '',

      nextPeriodLabel:
          j['next_period_label']
                  ?.toString() ??
              j['next_period']
                  ?.toString() ??
              '',

      fertileWindowLabel:
          j['fertile_window_label']
                  ?.toString() ??
              j['fertile_window']
                  ?.toString() ??
              '',

      cycleProgress:
          (j['cycle_progress'] as num?)
                  ?.toDouble() ??
              0.0,

      factorWeights:
          factors,

      pcosRisk:
          pcosStatus,

      avgCycleLength:
          avgCycle,

      avgPeriodLength:
          (j['avg_period_length'] as num?)
                  ?.toInt() ??
              5,

      cycleLengthHistory:
          history,

      predictedCycleLength:
          predictedCycle,
    );
  }
}