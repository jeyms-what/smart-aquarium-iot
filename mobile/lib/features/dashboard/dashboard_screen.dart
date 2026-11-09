import 'package:flutter/material.dart';

import '../../data/models/telemetry_reading.dart';
import '../monitoring/monitoring_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.controller,
    required this.onToggleTheme,
    required this.isDarkMode,
    super.key,
  });

  final MonitoringController controller;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final snapshot = controller.snapshot;
        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                title: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Smart Aquarium', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text('Monitoring and care', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: 'Refresh measurements',
                    onPressed: controller.isRefreshing ? null : controller.refresh,
                    icon: controller.isRefreshing
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                  ),
                  IconButton(
                    tooltip: isDarkMode ? 'Switch to light theme' : 'Switch to dark theme',
                    onPressed: onToggleTheme,
                    icon: Icon(isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                sliver: SliverList.list(
                  children: [
                    _ConnectionCard(snapshot: snapshot, isRefreshing: controller.isRefreshing),
                    const SizedBox(height: 18),
                    Text('Water conditions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _MeasurementCard(
                          title: 'Temperature',
                          unit: '°C',
                          icon: Icons.thermostat_outlined,
                          reading: snapshot.readingFor('water_temperature'),
                        ),
                        _MeasurementCard(
                          title: 'Water level',
                          unit: 'cm',
                          icon: Icons.water_outlined,
                          reading: snapshot.readingFor('water_level'),
                        ),
                        _MeasurementCard(
                          title: 'Turbidity',
                          unit: 'NTU or raw ADC',
                          icon: Icons.opacity_outlined,
                          reading: snapshot.readingFor('turbidity'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text('Equipment', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    const _EquipmentStatus(
                      title: 'Water pump',
                      detail: 'State unavailable — verified device feedback is not implemented.',
                      icon: Icons.water,
                    ),
                    const SizedBox(height: 8),
                    const _EquipmentStatus(
                      title: 'Automatic feeder',
                      detail: 'State unavailable — verified device feedback is not implemented.',
                      icon: Icons.pets_outlined,
                    ),
                    const SizedBox(height: 18),
                    Text('Care recommendations', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    const _EmptyPanel(
                      icon: Icons.eco_outlined,
                      title: 'No recommendation available',
                      message: 'Recommendations will appear after valid readings and a fish-species profile are configured.',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      snapshot.lastSuccessfulSyncAt == null
                          ? 'Last successful synchronization: none'
                          : 'Last successful synchronization: ${_formatTimestamp(snapshot.lastSuccessfulSyncAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Readings are labelled by measurement time. Old records are not presented as live data.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({required this.snapshot, required this.isRefreshing});

  final MonitoringSnapshot snapshot;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (title, statusLabel, icon) = switch (snapshot.source) {
      MonitoringSource.remote => ('Backend reachable', 'SERVER', Icons.cloud_done_outlined),
      MonitoringSource.cached => ('Showing saved measurements', 'CACHED', Icons.storage_outlined),
      MonitoringSource.offline => ('Offline — no saved readings', 'OFFLINE', Icons.cloud_off_outlined),
      MonitoringSource.notConfigured => ('Remote API not configured', 'NOT SET', Icons.settings_ethernet_outlined),
    };

    return Card(
      color: colors.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.primary, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(snapshot.message, style: const TextStyle(fontSize: 12)),
                  if (snapshot.lastCheckedAt != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Last checked: ${_formatTimestamp(snapshot.lastCheckedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                if (isRefreshing) ...[
                  const SizedBox(height: 8),
                  const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  const _MeasurementCard({
    required this.title,
    required this.unit,
    required this.icon,
    required this.reading,
  });

  final String title;
  final String unit;
  final IconData icon;
  final TelemetryReading? reading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Capture the nullable field in a local variable so Dart can promote it
    // after the null check. Public properties aren't promotable across reads.
    final currentReading = reading;
    final valid = currentReading?.hasUsableValue ?? false;
    final displayedUnit = valid ? currentReading!.displayUnit : unit;
    final age = currentReading == null ? null : _age(currentReading.measuredAt);
    final status = currentReading == null
        ? 'No reading $unit'
        : !valid
            ? 'Invalid or unavailable reading'
            : currentReading.timeQuality == 'uptime_only'
                ? 'Device wall-clock time is unverified'
                : age == 'device time ahead'
                    ? 'Device timestamp is ahead of phone time'
                    : currentReading.isStale()
                        ? 'STALE · $age old'
                        : 'Measured $age ago';

    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 42) / 2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colors.primary),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 5),
              Text(
                valid ? currentReading!.formattedValue : '—',
                style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w700),
              ),
              Text(displayedUnit, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(
                status,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: currentReading?.isStale() == true ? colors.error : colors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EquipmentStatus extends StatelessWidget {
  const _EquipmentStatus({required this.title, required this.detail, required this.icon});
  final String title;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(detail),
        trailing: const Icon(Icons.help_outline),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  Text(message, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTimestamp(DateTime timestamp) {
  final local = timestamp.toLocal();
  final date = '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  final time = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}

String _age(DateTime timestamp) {
  final difference = DateTime.now().difference(timestamp.toLocal());
  if (difference.isNegative) return 'device time ahead';
  if (difference.inSeconds < 60) return '${difference.inSeconds}s';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m';
  if (difference.inHours < 24) return '${difference.inHours}h';
  return '${difference.inDays}d';
}
