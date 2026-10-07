/// Recommendation from analytics.
class Recommendation {
  final String id;
  final String title;
  final String detail;
  final double estimatedSaving;
  bool applied;
  Recommendation({
    required this.id,
    required this.title,
    required this.detail,
    required this.estimatedSaving,
    this.applied = false,
  });
}

/// Anomaly detected by analytics.
class Anomaly {
  final String id;
  final String deviceName;
  final String description;
  final String severity; // LOW, MEDIUM, HIGH
  final String detectedAt;
  bool resolved;
  Anomaly({
    required this.id,
    required this.deviceName,
    required this.description,
    required this.severity,
    required this.detectedAt,
    this.resolved = false,
  });
}

/// Bill prediction.
class BillPrediction {
  final double projectedCost;
  final double projectedKwh;
  final double confidence;
  final String closingDate;
  const BillPrediction({
    required this.projectedCost,
    required this.projectedKwh,
    required this.confidence,
    required this.closingDate,
  });
}

/// Consumption ranking item.
class ConsumptionRanking {
  final int rank;
  final String deviceName;
  final double kwh;
  final double cost;
  const ConsumptionRanking({
    required this.rank,
    required this.deviceName,
    required this.kwh,
    required this.cost,
  });
}
