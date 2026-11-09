import 'package:flutter/material.dart';

import '../../data/models/telemetry_reading.dart';
import '../monitoring/monitoring_controller.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({required this.controller, super.key});

  final MonitoringController controller;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<TelemetryReading>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = widget.controller.loadHistory();
  }

  void _reload() {
    setState(() {
      _historyFuture = widget.controller.loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('History and analytics'),
        actions: [IconButton(onPressed: _reload, tooltip: 'Refresh history', icon: const Icon(Icons.refresh))],
      ),
      body: FutureBuilder<List<TelemetryReading>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load local history: ${snapshot.error}', textAlign: TextAlign.center),
              ),
            );
          }

          final readings = snapshot.data ?? const <TelemetryReading>[];
          if (readings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.query_stats, size: 48, color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text('No historical records', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 6),
                    const Text(
                      'History will appear after actual telemetry records have been received and saved on this device.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: readings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final reading = readings[index];
              final value = reading.hasUsableValue
                  ? '${reading.formattedValue} ${reading.displayUnit}'
                  : 'Invalid / unavailable';
              return Card(
                child: ListTile(
                  leading: Icon(
                    reading.hasUsableValue ? Icons.sensors : Icons.sensors_off,
                    color: reading.hasUsableValue
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                  title: Text(reading.displayName),
                  subtitle: Text(
                    '${reading.measuredAt.toLocal()}\nSequence ${reading.sequenceNumber} · ${reading.timeQuality}',
                  ),
                  isThreeLine: true,
                  trailing: Text(value, textAlign: TextAlign.end),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
