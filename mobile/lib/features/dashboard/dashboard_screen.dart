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
                titleSpacing: 20,
                title: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF16C6C1), Color(0xFF087F95)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.water, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 11),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AQUASENSE', style: TextStyle(fontSize: 15, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
                        Text('SMART AQUARIUM', style: TextStyle(fontSize: 9, letterSpacing: 1.8, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: 'Refresh measurements',
                    onPressed: controller.isRefreshing ? null : controller.refresh,
                    icon: controller.isRefreshing
                        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh_rounded),
                  ),
                  IconButton(
                    tooltip: isDarkMode ? 'Switch to light theme' : 'Switch to dark theme',
                    onPressed: onToggleTheme,
                    icon: Icon(isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
                sliver: SliverList.list(
                  children: [
                    _AquariumHero(snapshot: snapshot),
                    const SizedBox(height: 24),
                    const _SectionHeading(
                      eyebrow: 'LIVE TELEMETRY',
                      title: 'Water conditions',
                      trailing: '3 SENSORS',
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cardWidth = (constraints.maxWidth - 12) / 2;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: cardWidth,
                              child: _MeasurementCard(
                                title: 'Temperature',
                                unit: '°C',
                                icon: Icons.thermostat_rounded,
                                accent: const Color(0xFFFFA66B),
                                reading: snapshot.readingFor('water_temperature'),
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _MeasurementCard(
                                title: 'Water level',
                                unit: 'cm',
                                icon: Icons.water_drop_rounded,
                                accent: const Color(0xFF43C6E8),
                                reading: snapshot.readingFor('water_level'),
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _MeasurementCard(
                                title: 'Turbidity',
                                unit: 'NTU or raw ADC',
                                icon: Icons.blur_on_rounded,
                                accent: const Color(0xFF9D9AFF),
                                reading: snapshot.readingFor('turbidity'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 25),
                    const _SectionHeading(eyebrow: 'HARDWARE STATUS', title: 'Equipment'),
                    const SizedBox(height: 12),
                    const _EquipmentStatus(
                      title: 'Water pump',
                      detail: 'Device feedback not yet connected',
                      icon: Icons.water_rounded,
                      accent: Color(0xFF43C6E8),
                    ),
                    const SizedBox(height: 10),
                    const _EquipmentStatus(
                      title: 'Automatic feeder',
                      detail: 'Device feedback not yet connected',
                      icon: Icons.ramen_dining_rounded,
                      accent: Color(0xFFFFB86B),
                    ),
                    const SizedBox(height: 25),
                    const _SectionHeading(eyebrow: 'PERSONALIZED FISH CARE', title: 'Care insights'),
                    const SizedBox(height: 12),
                    const _EmptyPanel(
                      icon: Icons.eco_rounded,
                      title: 'No recommendation available',
                      message: 'Connect valid sensor readings and add your fish species profile to receive relevant care recommendations.',
                    ),
                    const SizedBox(height: 20),
                    Text(
                      snapshot.lastSuccessfulSyncAt == null
                          ? 'Last successful sync: none yet'
                          : 'Last successful sync: ${_formatTimestamp(snapshot.lastSuccessfulSyncAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Measurements are shown with their recorded timestamps. Older readings are never presented as live data.',
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

class _AquariumHero extends StatelessWidget {
  const _AquariumHero({required this.snapshot});
  final MonitoringSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final (headline, status, icon) = switch (snapshot.source) {
      MonitoringSource.remote => ('Cloud connection active', 'CONNECTED', Icons.cloud_done_rounded),
      MonitoringSource.cached => ('Showing saved readings', 'CACHED DATA', Icons.storage_rounded),
      MonitoringSource.offline => ('Aquarium is offline', 'OFFLINE', Icons.cloud_off_rounded),
      MonitoringSource.notConfigured => ('Remote API not configured', 'SETUP REQUIRED', Icons.sensors_rounded),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF123D4B), Color(0xFF087F87), Color(0xFF07556C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF079A9A).withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -35,
            child: Icon(Icons.waves_rounded, size: 150, color: Colors.white.withValues(alpha: 0.07)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(30)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 14, color: const Color(0xFF8EF2E4)),
                        const SizedBox(width: 6),
                        Text(status, style: const TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.more_horiz_rounded, color: Colors.white70),
                ],
              ),
              const SizedBox(height: 22),
              const Text('YOUR AQUARIUM', style: TextStyle(color: Color(0xFF9DE9E1), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
              const SizedBox(height: 7),
              Text(headline, style: const TextStyle(color: Colors.white, fontSize: 23, height: 1.15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 9),
              Text(snapshot.message, style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 12, height: 1.45)),
              const SizedBox(height: 18),
              Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.16),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, color: Color(0xFF9DE9E1), size: 15),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      snapshot.lastCheckedAt == null ? 'Not checked yet' : 'Last checked ${_formatTimestamp(snapshot.lastCheckedAt!)}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
                    ),
                  ),
                  const Text('PULL TO REFRESH', style: TextStyle(color: Color(0xFF9DE9E1), fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.eyebrow, required this.title, this.trailing});
  final String eyebrow;
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow, style: TextStyle(color: colors.primary, fontSize: 9, letterSpacing: 1.7, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4)),
            ],
          ),
        ),
        if (trailing != null)
          Text(trailing!, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  const _MeasurementCard({
    required this.title,
    required this.unit,
    required this.icon,
    required this.accent,
    required this.reading,
  });

  final String title;
  final String unit;
  final IconData icon;
  final Color accent;
  final TelemetryReading? reading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: accent, size: 19),
              ),
              const Spacer(),
              Icon(valid ? Icons.check_circle_outline_rounded : Icons.more_horiz_rounded, color: colors.onSurfaceVariant, size: 17),
            ],
          ),
          const SizedBox(height: 15),
          Text(title, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          Text(
            valid ? currentReading!.formattedValue : '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 29, height: 1.05, fontWeight: FontWeight.w800, letterSpacing: -1),
          ),
          const SizedBox(height: 4),
          Text(displayedUnit, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10)),
          const SizedBox(height: 12),
          Text(
            status,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9, height: 1.3, color: currentReading?.isStale() == true ? colors.error : colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _EquipmentStatus extends StatelessWidget {
  const _EquipmentStatus({required this.title, required this.detail, required this.icon, required this.accent});
  final String title;
  final String detail;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 3),
                Text(detail, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10)),
              ],
            ),
          ),
          Icon(Icons.lock_outline_rounded, color: colors.onSurfaceVariant, size: 18),
        ],
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
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: colors.primary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Text(message, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11, height: 1.45)),
              ],
            ),
          ),
        ],
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
