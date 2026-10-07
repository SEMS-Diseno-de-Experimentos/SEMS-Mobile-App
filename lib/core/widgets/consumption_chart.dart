import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/core/config/theme.dart';
import 'package:flutter_application_1/features/monitoring/domain/entities/energy.dart';
import 'package:flutter_application_1/core/providers/language_provider.dart';

class ConsumptionChart extends StatelessWidget {
  final List<EnergyReading> readings;
  
  const ConsumptionChart({super.key, required this.readings});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (readings.isEmpty) {
      return SizedBox(
        height: 250,
        child: Center(child: Text(lang.t("Sin datos", "No data"))),
      );
    }

    final maxKwh = readings.map((r) => r.kwh).reduce((a, b) => a > b ? a : b);
    final maxY = ((maxKwh / 5).ceil() * 5).toDouble() + 5.0; // round up for padding

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => isDark ? SemsColors.navy700 : SemsColors.slate800,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final r = readings[groupIndex];
                return BarTooltipItem(
                  '${r.date}\n',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  children: <TextSpan>[
                    TextSpan(
                      text: '${r.kwh.toStringAsFixed(1)} kWh\n',
                      style: const TextStyle(color: SemsColors.blue300, fontWeight: FontWeight.w500),
                    ),
                    TextSpan(
                      text: 'S/ ${r.cost.toStringAsFixed(2)}',
                      style: const TextStyle(color: SemsColors.emerald300, fontWeight: FontWeight.w500),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value.toInt() >= readings.length) return const SizedBox.shrink();
                  // Show roughly every 3rd day for space
                  if (value.toInt() % 3 != 0 && value.toInt() != readings.length - 1) {
                    return const SizedBox.shrink();
                  }
                  final dateStr = readings[value.toInt()].date;
                  final dayStr = dateStr.split('-').last;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      dayStr,
                      style: TextStyle(
                        color: isDark ? SemsColors.slate400 : SemsColors.slate500,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? SemsColors.navy700 : SemsColors.slate200,
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: readings.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.kwh,
                  color: SemsColors.blue600,
                  width: 12,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
