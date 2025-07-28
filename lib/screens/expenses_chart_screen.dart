import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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

      if (expenses.isNotEmpty) {
        double maxCost = 0;
        for (int i = 0; i < expenses.length; i++) {
          final dateStr = expenses[i]['date'] as String;
          final totalCost = (expenses[i]['total_cost'] as num).toDouble();
          _spots.add(FlSpot(i.toDouble(), totalCost));
          if (totalCost > maxCost) {
            maxCost = totalCost;
          }
          _bottomTitles
              .add(DateFormat('dd.MM').format(DateTime.parse(dateStr)));
        }
        _maxY = maxCost * 1.2; // Add some padding to the max Y value
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
    return Padding(
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
                              return const Text('');
                            },
                            interval: (_bottomTitles.length / 5)
                                .ceilToDouble(), // Show about 5 titles
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
                      maxX: (_spots.length - 1).toDouble(),
                      minY: 0,
                      maxY: _maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _spots,
                          isCurved: true,
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
    );
  }
}
