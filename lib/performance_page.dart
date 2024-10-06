import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PerformancePage extends StatefulWidget {
  const PerformancePage({Key? key}) : super(key: key);

  @override
  _PerformancePageState createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<AnimationController> _chartControllers;
  final List<Color> gradientColors = [
    const Color(0xFF2D2D2D),
    const Color(0xFFD7E4C0),
    const Color(0xFFFFC0CB),
  ];

  List<List<FlSpot>> chartData = List.generate(4, (_) => [const FlSpot(0, 0)]);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();

    _chartControllers = List.generate(
      4,
      (_) => AnimationController(
        duration: const Duration(seconds: 3),
        vsync: this,
      )..repeat(),
    );

    // Inicializar datos con valores aleatorios
    for (int i = 0; i < chartData.length; i++) {
      for (int j = 0; j < 10; j++) {
        chartData[i].add(FlSpot(j.toDouble(), Random().nextDouble() * 100));
      }
    }

    // Simular datos en tiempo real
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          for (int i = 0; i < chartData.length; i++) {
            if (chartData[i].length > 10) {
              chartData[i].removeAt(0);
            }
            chartData[i].add(FlSpot(
              chartData[i].length.toDouble(),
              Random().nextDouble() * 100,
            ));
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _chartControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Rendimiento'),
        backgroundColor: const Color(0xFF2D2D2D),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rendimiento del Sistema',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D2D2D),
                  ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildPerformanceCard('CPU', 0),
                  _buildPerformanceCard('RAM', 1),
                  _buildPerformanceCard('Almacenamiento', 2),
                  _buildPerformanceCard('Red', 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(String title, int index) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedBuilder(
                animation: _chartControllers[index],
                builder: (context, child) {
                  return LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 9,
                      minY: 0,
                      maxY: 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: chartData[index],
                          isCurved: true,
                          color: gradientColors[0],
                          barWidth: 5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: gradientColors[0].withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
