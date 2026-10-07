/// Dashboard summary — aggregated KPI data.
class DashboardSummary {
  final double currentMonthCost;
  final double savingAmount;
  final double savingPct;
  final double projectedCost;
  final double totalKwh;
  final int activeDevices;
  final int unreadAlerts;
  const DashboardSummary({
    required this.currentMonthCost,
    required this.savingAmount,
    required this.savingPct,
    required this.projectedCost,
    required this.totalKwh,
    required this.activeDevices,
    required this.unreadAlerts,
  });
}
