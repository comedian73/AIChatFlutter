import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:collection'; // Import for SplayTreeMap
import '../services/database_service.dart';

class ExpensesChartScreen extends StatefulWidget {
  const ExpensesChartScreen({super.key});

  @override
  State<ExpensesChartScreen> createState() => _ExpensesChartScreenState();
}

class _ExpensesChartScreenState extends State<ExpensesChartScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  List<FlSpot> _spots = [];
  double _maxY = 0;
  List<String> _bottomTitles = [];
  bool _isShortPeriod = false; // New variable to control date format on X-axis

  @override
  void initState() {
    super.initState();
    _initializeDates();
  }

  void _initializeDates() {
    final now = DateTime.now();
    _endDate = DateTime(
        now.year, now.month, now.day, 23, 59, 59); // End of current day
    _startDate = DateTime(now.year, now.month, 1); // Start of current month
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    if (_startDate == null || _endDate == null) return;

    final expenses = await DatabaseService().getExpensesByPeriod(
      _startDate!,
      _endDate!
          .add(const Duration(days: 1))
          .subtract(const Duration(seconds: 1)), // Include end date fully
    );

    setState(() {
      _spots = [];
      _maxY = 0;
      _bottomTitles = [];

      final int daysDifference = _endDate!.difference(_startDate!).inDays;
      _isShortPeriod = daysDifference <= 7;

      final Map<DateTime, double> dailyExpenses = SplayTreeMap();
      for (var expense in expenses) {
        final date = DateTime.parse(expense['date'] as String);
        final dateOnly = DateTime(date.year, date.month, date.day);
        dailyExpenses[dateOnly] = (dailyExpenses[dateOnly] ?? 0.0) +
            (expense['total_cost'] as num).toDouble();
      }

      double maxCost = 0;
      int dayIndex = 0;
      for (DateTime d = _startDate!;
          d.isBefore(_endDate!.add(const Duration(days: 1)));
          d = d.add(const Duration(days: 1))) {
        final dateOnly = DateTime(d.year, d.month, d.day);
        final totalCost = dailyExpenses[dateOnly] ?? 0.0;
        _spots.add(FlSpot(dayIndex.toDouble(), totalCost));
        if (totalCost > maxCost) {
          maxCost = totalCost;
        }
        _bottomTitles.add(DateFormat('dd.MM.yyyy')
            .format(dateOnly)); // Placeholder, will be formatted later
        dayIndex++;
      }

      _maxY = (_spots.isNotEmpty
              ? _spots.map((e) => e.y).reduce((a, b) => a > b ? a : b)
              : 0) *
          1.2;
      if (_maxY == 0) {
        _maxY = 10.0;
      }
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      end: _endDate ?? DateTime.now(),
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: initialDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue, // Header background color
              onPrimary: Colors.white, // Header text color
              surface: Color(0xFF333333), // Calendar background color
              onSurface: Colors.white, // Calendar text color
            ),
            dialogBackgroundColor: const Color(0xFF262626),
          ),
          child: child!,
        );
      },
    );

    if (picked != null &&
        (picked.start != _startDate || picked.end != _endDate)) {
      setState(() {
        _startDate = picked.start;
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day,
            23, 59, 59); // Set end of day
      });
      _fetchExpenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => _selectDateRange(context),
              child: Text(
                _startDate == null || _endDate == null
                    ? 'Выберите период'
                    : '${DateFormat('dd.MM.yyyy').format(_startDate!)} - ${DateFormat('dd.MM.yyyy').format(_endDate!)}',
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _spots.isEmpty
                  ? const Center(
                      child: Text('Нет данных о расходах за выбранный период.'))
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 &&
                                    value.toInt() < _bottomTitles.length) {
                                  final DateTime date = _startDate!
                                      .add(Duration(days: value.toInt()));
                                  String format;
                                  if (_isShortPeriod) {
                                    format = 'dd'; // Only day for short periods
                                  } else {
                                    format =
                                        'dd.MM'; // Day and month for longer periods
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      DateFormat(format).format(date),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                              interval: (_bottomTitles.length / 5)
                                  .ceilToDouble()
                                  .clamp(1.0, double.infinity),
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toStringAsFixed(2),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                );
                              },
                              reservedSize: 40,
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                              color: const Color(0xff37434d), width: 1),
                        ),
                        minX: 0,
                        maxX: (_bottomTitles.length - 1).toDouble(),
                        minY: 0,
                        maxY: _maxY,
                        lineBarsData: [
                          LineChartBarData(
                            spots: _spots,
                            isCurved:
                                false, // Changed to false to prevent dipping below zero
                            color: Colors.blue,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
