import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'package:pocketdoctor/chatbot_page.dart';

class MedBotPage extends StatefulWidget {
  const MedBotPage({super.key});

  @override
  State<MedBotPage> createState() => _MedBotPageState();
}

class _MedBotPageState extends State<MedBotPage> {
  String _status = 'Disconnected';
  Timer? _timer;
  final List<FlSpot> _ecgDataPoints = [];
  double _ecgMinY = -1.0;
  double _ecgMaxY = 1.0;

  Map<String, dynamic> _sensorData = {
    'temperature': 'N/A',
    'humidity': 'N/A',
    'pulse_raw': 'N/A',
    'ecg_voltage': 'N/A',
    'is_touched': false,
  };

  @override
  void initState() {
    super.initState();
    _connectToBot();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.1.4:5000/data'))
          .timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _sensorData = json.decode(response.body);
            _status = 'Connected';

            final ecgVoltage = _sensorData['ecg_voltage'];
            if (ecgVoltage is num) {
              final double voltage = ecgVoltage.toDouble();
              _ecgDataPoints
                  .add(FlSpot(_ecgDataPoints.length.toDouble(), voltage));
              if (_ecgDataPoints.length > 100) {
                _ecgDataPoints.removeAt(0);
              }
              if (voltage < _ecgMinY) _ecgMinY = voltage;
              if (voltage > _ecgMaxY) _ecgMaxY = voltage;
            }
          });
        }
      } else {
        if (mounted) setState(() => _status = 'Error: Failed to fetch data');
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Error: Not connected to Med-Bot');
    }
  }

  void _connectToBot() {
    if (_timer?.isActive ?? false) {
      _timer?.cancel();
      setState(() => _status = 'Disconnected');
    } else {
      setState(() => _status = 'Connecting...');
      _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        _fetchData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Activities',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.grey[100],
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.deepPurple[100],
              child: const Icon(Icons.person, color: Colors.deepPurple),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSensorGrid(),
          const SizedBox(height: 20),
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildSensorGrid() {
    return StaggeredGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        StaggeredGridTile.count(
          crossAxisCellCount: 1,
          mainAxisCellCount: 1.3,
          child: _buildSensorCard(
            title: 'Heart',
            child: _buildHeartRateChart(),
          ),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 1,
          mainAxisCellCount: 1,
          child: _buildSensorCard(
            title: 'Pulse Rate',
            child: _buildMetricDisplay(
              value: _sensorData['pulse_raw'].toString(),
              unit: 'BPM',
              icon: Icons.favorite,
              color: Colors.red,
            ),
          ),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 1,
          mainAxisCellCount: 1,
          child: _buildSensorCard(
            title: 'Temperature',
            child: _buildMetricDisplay(
              value: _sensorData['temperature'].toString(),
              unit: '°C',
              icon: Icons.thermostat,
              color: Colors.orange,
            ),
          ),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 1,
          mainAxisCellCount: 1.3,
          child: _buildSensorCard(
            title: 'Humidity',
            child: _buildMetricDisplay(
              value: _sensorData['humidity'].toString(),
              unit: '%',
              icon: Icons.water_drop,
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSensorCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildMetricDisplay({
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 40, color: color),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            text: value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                text: ' $unit',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.normal),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeartRateChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: _ecgDataPoints.length.toDouble() - 1 > 0
            ? _ecgDataPoints.length.toDouble() - 1
            : 1,
        minY: _ecgMinY,
        maxY: _ecgMaxY,
        lineBarsData: [
          LineChartBarData(
            spots: _ecgDataPoints.isNotEmpty
                ? _ecgDataPoints
                : [const FlSpot(0, 0)],
            isCurved: true,
            color: Colors.deepPurple,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.deepPurple.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    final isConnected = _status == 'Connected';
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _connectToBot,
            icon: Icon((_timer?.isActive ?? false)
                ? Icons.document_scanner_outlined
                : Icons.document_scanner),
            label: Text((_timer?.isActive ?? false) ? 'Stop Scan' : 'Scan Me'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: isConnected
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ChatbotPage()))
                : null,
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Chat with Bot'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
