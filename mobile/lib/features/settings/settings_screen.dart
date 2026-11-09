import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.devices_other),
            title: Text('Aquarium device'),
            subtitle: Text('Device connection is not confirmed until device heartbeat support is integrated.'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('Development API'),
            subtitle: Text(AppConfig.apiConfigurationLabel),
          ),
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('Device identifier'),
            subtitle: Text(AppConfig.deviceId),
          ),
          const Divider(height: 1),
          const ListTile(
            leading: Icon(Icons.storage_outlined),
            title: Text('Local database'),
            subtitle: Text('SQLite stores received telemetry and synchronization timestamps on this device.'),
          ),
          const Divider(height: 1),
          const ListTile(
            leading: Icon(Icons.security_outlined),
            title: Text('Development security'),
            subtitle: Text('The temporary bearer token is debug-only. Do not put a development token in a release APK or expose the local backend to the internet.'),
          ),
          const Divider(height: 1),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Application version'),
            subtitle: Text('0.3.0 — telemetry cache and read-only API integration'),
          ),
        ],
      ),
    );
  }
}
