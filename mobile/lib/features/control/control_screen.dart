import 'package:flutter/material.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Equipment control')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Controls are locked', style: TextStyle(fontWeight: FontWeight.w700)),
                        SizedBox(height: 5),
                        Text('Pair and authenticate the ESP32, then implement device acknowledgments and physical feedback before enabling remote controls.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _ControlTile(title: 'Water pump', subtitle: 'Unavailable — no device state received', icon: Icons.water_drop_outlined),
          const SizedBox(height: 10),
          const _ControlTile(title: 'Automatic feeder', subtitle: 'Unavailable — no device state received', icon: Icons.pets_outlined),
          const SizedBox(height: 18),
          Text('Safety rule: a command is not successful until the device acknowledges it and the resulting physical state is verified.', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ControlTile extends StatelessWidget {
  const _ControlTile({required this.title, required this.subtitle, required this.icon});
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Switch(value: false, onChanged: null),
      ),
    );
  }
}
