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
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('History and analytics'),
        titleSpacing: 20,
        actions: [IconButton(onPressed: _reload, tooltip: 'Refresh history', icon: const Icon(Icons.refresh_rounded))],
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
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.55)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(22)),
                        child: Icon(Icons.query_stats_rounded, size: 34, color: colors.primary),
                      ),
                      const SizedBox(height: 17),
                      Text('No historical records', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(
                        'History will appear after actual telemetry records have been received and saved on this device.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.onSurfaceVariant, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: readings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 9),
            itemBuilder: (context, index) {
              final reading = readings[index];
              final value = reading.hasUsableValue
                  ? '${reading.formattedValue} ${reading.displayUnit}'
                  : 'Invalid / unavailable';
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(reading.hasUsableValue ? Icons.sensors_rounded : Icons.sensors_off_rounded, color: reading.hasUsableValue ? colors.primary : colors.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(reading.displayName, style: const TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text('${reading.measuredAt.toLocal()} · Sequence ${reading.sequenceNumber}', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
