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
  bool _showTimeOnXAxis = false; // New variable to control time display

  @override
  void initState() {
    super.initState();
    _initializeDates();
  }

  void _initializeDates() {
    final now = DateTime.now();
    _endDate = DateTime(now.year, now.month, now.day);
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
      _showTimeOnXAxis = daysDifference <= 7;

      if (_showTimeOnXAxis) {
        // If period is 7 days or less, show time on X-axis
        final Map<DateTime, double> timedExpenses = SplayTreeMap();
        for (var expense in expenses) {
          final date = DateTime.parse(expense['date'] as String);
          final totalCost = (expense['total_cost'] as num).toDouble();
          timedExpenses[date] = (timedExpenses[date] ?? 0.0) +
              totalCost; // Aggregate expenses for the same timestamp
        }

        double maxCost = 0;
        // Calculate total minutes from start date for x-axis
        final int totalMinutes = _endDate!.difference(_startDate!).inMinutes;

        // Generate spots for each minute within the range, or for each expense
        // For simplicity, let's just plot the actual expense times for now.
        // If there are no expenses, we still need a range.
        if (timedExpenses.isEmpty) {
          _spots.add(FlSpot(0, 0));
          _spots.add(FlSpot(totalMinutes.toDouble(), 0));
        } else {
          for (var entry in timedExpenses.entries) {
            final double xValue =
                entry.key.difference(_startDate!).inMinutes.toDouble();
            _spots.add(FlSpot(xValue, entry.value));
            if (entry.value > maxCost) {
              maxCost = entry.value;
            }
          }
        }

        // For time-based charts, _bottomTitles is not directly used for labels.
        // The getTitlesWidget will format the value directly.
        // We can still populate _bottomTitles with dummy values or clear it if not needed.
        // For now, let's ensure it's empty for time-based charts.
        _bottomTitles.clear();
      } else {
        // If period is more than 7 days, show daily expenses
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
          _bottomTitles.add(DateFormat('dd.MM').format(dateOnly));
          dayIndex++;
        }
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
        _endDate = picked.end;
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
                                if (_showTimeOnXAxis) {
                                  // For time-based axis, value is minutes from start date
                                  final DateTime labelTime = _startDate!
                                      .add(Duration(minutes: value.toInt()));
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      DateFormat('HH:mm').format(labelTime),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                } else {
                                  // For date-based axis
                                  if (value.toInt() >= 0 &&
                                      value.toInt() < _bottomTitles.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        _bottomTitles[value.toInt()],
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                        ),
                                      ),
                                    );
                                  }
                                }
                                return const Text('');
                              },
                              interval: _showTimeOnXAxis
                                  ? (_endDate!
                                              .difference(_startDate!)
                                              .inMinutes /
                                          5)
                                      .ceilToDouble()
                                      .clamp(
                                          1.0,
                                          double
                                              .infinity) // Ensure interval is at least 1
                                  : (_bottomTitles.length / 5)
                                      .ceilToDouble(), // Show about 5 titles for dates
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
                        maxX: _showTimeOnXAxis
                            ? _endDate!
                                .difference(_startDate!)
                                .inMinutes
                                .toDouble()
                            : (_bottomTitles.length - 1)
                                .toDouble(), // Use total minutes or day index
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
