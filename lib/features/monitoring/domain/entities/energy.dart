/// Daily energy reading.
class EnergyReading {
  final String date; // YYYY-MM-DD
  final double kwh;
  final double cost;
  const EnergyReading({required this.date, required this.kwh, required this.cost});
}

/// Consumption breakdown per device.
class DeviceConsumption {
  final String deviceId;
  final String deviceName;
  final double kwh;
  final double cost;
  final int pct;
  const DeviceConsumption({
    required this.deviceId,
    required this.deviceName,
    required this.kwh,
    required this.cost,
    required this.pct,
  });
}

/// Energy meter.
class EnergyMeter {
  final String meterId;
  final String name;
  final bool active;
  final double lastReadingKwh;
  const EnergyMeter({
    required this.meterId,
    required this.name,
    required this.active,
    required this.lastReadingKwh,
  });
}

/// Period comparison.
class PeriodComparison {
  final double currentKwh;
  final double previousKwh;
  final double currentCost;
  final double previousCost;
  final double deltaPct;
  const PeriodComparison({
    required this.currentKwh,
    required this.previousKwh,
    required this.currentCost,
    required this.previousCost,
    required this.deltaPct,
  });
}

/// Period summary (weekly/monthly).
class PeriodSummary {
  final String key;
  final String label;
  final double kwh;
  final double cost;
  const PeriodSummary({
    required this.key,
    required this.label,
    required this.kwh,
    required this.cost,
  });
}

class ConsumptionSummary {
  final List<PeriodSummary> weekly;
  final List<PeriodSummary> monthly;
  const ConsumptionSummary({required this.weekly, required this.monthly});
}
