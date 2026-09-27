
class Prediction {
  final int currentDay;
  final String phaseLabel;

  final String nextPeriodLabel;
  final String fertileWindowLabel;

  final double cycleProgress;
  final double confidence;

  final Map<String, double> factorWeights;

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
    required this.confidence,
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
    // ACTUAL ML FEATURE IMPORTANCE
    // ==========================================================

    final rawFactors = j['factor_weights'];

    final Map<String, double> factors = {};

    if (rawFactors is Map) {
      rawFactors.forEach((key, value) {
        if (value is num) {
          factors[key.toString()] = value.toDouble();
        }
      });
    }


    // ==========================================================
    // CYCLE HISTORY
    // ==========================================================

    final historyRaw = j['cycle_length_history'];

    final List<int> history = [];

    if (historyRaw is List) {
      for (final item in historyRaw) {
        if (item is num) {
          history.add(item.toInt());
        }
      }
    }


    // ==========================================================
    // AVERAGE CYCLE LENGTH
    // ==========================================================

    final avgCycle =
        (j['avg_cycle_length'] as num?)?.toInt() ?? 28;

    if (history.isEmpty) {
      history.add(avgCycle);
    }


    // ==========================================================
    // PREDICTED CYCLE LENGTH
    // ==========================================================

    final predictedCycle =
        (j['predicted_cycle_length'] as num?)?.toInt() ??
        (j['prediction'] as num?)?.toInt() ??
        avgCycle;


    // ==========================================================
    // CONFIDENCE
    // ==========================================================

    final confidence =
        (j['confidence'] as num?)?.toDouble() ?? 0.0;


    // ==========================================================
    // PCOS STATUS
    // ==========================================================

    String pcosStatus =
        j['pcos_risk']?.toString() ??
        'No PCOS reported';

    if (pcosStatus.toLowerCase() == 'true') {
      pcosStatus = 'Reported PCOS';
    }

    if (pcosStatus.toLowerCase() == 'false') {
      pcosStatus = 'No PCOS reported';
    }


    // ==========================================================
    // NEXT PERIOD LABEL
    // ==========================================================

    String nextPeriodLabel = '';

    if (j['next_period_label'] != null) {
      nextPeriodLabel =
          j['next_period_label'].toString();
    }

    // Fallback only if backend label is missing.
    if (nextPeriodLabel.isEmpty &&
        j['next_period'] != null) {
      nextPeriodLabel =
          _formatDate(j['next_period'].toString());
    }


    // ==========================================================
    // FERTILE WINDOW LABEL
    // ==========================================================

    String fertileWindowLabel = '';

    if (j['fertile_window_label'] != null) {
      fertileWindowLabel =
          j['fertile_window_label'].toString();
    }

    // Fallback if backend label is missing.
    if (fertileWindowLabel.isEmpty) {
      final fertile = j['fertile_window'];

      if (fertile is Map) {
        final start = fertile['start']?.toString();
        final end = fertile['end']?.toString();

        if (start != null && end != null) {
          fertileWindowLabel =
              '${_formatDate(start)} - ${_formatDate(end)}';
        }
      }
    }


    // ==========================================================
    // PHASE
    // ==========================================================

    final phaseLabel =
        j['phase_label']?.toString() ?? '';


    // ==========================================================
    // RETURN PREDICTION
    // ==========================================================

    return Prediction(
      currentDay:
          (j['current_day'] as num?)?.toInt() ??
          (j['cycle_day_at_prediction'] as num?)?.toInt() ??
          1,

      phaseLabel:
          phaseLabel,

      nextPeriodLabel:
          nextPeriodLabel,

      fertileWindowLabel:
          fertileWindowLabel,

      cycleProgress:
          (j['cycle_progress'] as num?)?.toDouble() ??
          0.0,

      confidence:
          confidence,

      factorWeights:
          factors,

      pcosRisk:
          pcosStatus,

      avgCycleLength:
          avgCycle,

      avgPeriodLength:
          (j['avg_period_length'] as num?)?.toInt() ??
          5,

      cycleLengthHistory:
          history,

      predictedCycleLength:
          predictedCycle,
    );
  }


  // ============================================================
  // DATE FORMATTER
  // ============================================================

  static String _formatDate(String value) {
    try {
      final date = DateTime.parse(value);

      final day =
          date.day.toString().padLeft(2, '0');

      final month =
          date.month.toString().padLeft(2, '0');

      final year =
          date.year.toString();

      return '$day/$month/$year';
    } catch (_) {
      return value;
    }
  }
}

