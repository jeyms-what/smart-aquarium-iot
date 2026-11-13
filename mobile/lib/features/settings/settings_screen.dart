import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), titleSpacing: 20),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        children: [
          Text('DEVICE & CONNECTION', style: TextStyle(color: colors.primary, fontSize: 10, letterSpacing: 1.7, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.devices_other_rounded,
            title: 'Aquarium device',
            subtitle: 'Device connection is not confirmed until heartbeat support is integrated.',
          ),
          const SizedBox(height: 9),
          _SettingsTile(
            icon: Icons.cloud_outlined,
            title: 'Development API',
            subtitle: AppConfig.apiConfigurationLabel,
          ),
          const SizedBox(height: 9),
          _SettingsTile(
            icon: Icons.fingerprint_rounded,
            title: 'Device identifier',
            subtitle: AppConfig.deviceId,
          ),
          const SizedBox(height: 24),
          Text('STORAGE & SECURITY', style: TextStyle(color: colors.primary, fontSize: 10, letterSpacing: 1.7, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.storage_rounded,
            title: 'Local database',
            subtitle: 'SQLite stores received telemetry and synchronization timestamps on this device.',
          ),
          const SizedBox(height: 9),
          _SettingsTile(
            icon: Icons.security_rounded,
            title: 'Development security',
            subtitle: 'The temporary bearer token is debug-only. Never include it in a release APK or expose the local backend to the internet.',
          ),
          const SizedBox(height: 24),
          Text('ABOUT', style: TextStyle(color: colors.primary, fontSize: 10, letterSpacing: 1.7, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'Application version',
            subtitle: '0.3.0 — telemetry cache and read-only API integration',
          ),
          const SizedBox(height: 18),
          Center(child: Text('AQUASENSE  •  SMART AQUARIUM', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: colors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
