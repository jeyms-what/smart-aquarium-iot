import 'package:flutter/material.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment control'),
        titleSpacing: 20,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(23),
              gradient: const LinearGradient(
                colors: [Color(0xFF174B58), Color(0xFF12313E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFF8FE7D9), size: 27),
                SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Safety interlock active', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                      SizedBox(height: 6),
                      Text('Controls stay locked until the ESP32 is authenticated and actuator feedback is verified. This prevents unconfirmed commands from being treated as successful.', style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('ACTUATORS', style: TextStyle(color: colors.primary, fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text('Your equipment', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 13),
          const _ControlTile(title: 'Water pump', subtitle: 'No verified device state received', icon: Icons.water_drop_rounded, accent: Color(0xFF43C6E8)),
          const SizedBox(height: 11),
          const _ControlTile(title: 'Automatic feeder', subtitle: 'No verified device state received', icon: Icons.ramen_dining_rounded, accent: Color(0xFFFFB86B)),
          const SizedBox(height: 18),
          Text('A command is only successful after the device acknowledges it and the resulting physical state is verified.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant, height: 1.45)),
        ],
      ),
    );
  }
}

class _ControlTile extends StatelessWidget {
  const _ControlTile({required this.title, required this.subtitle, required this.icon, required this.accent});
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11)),
              ],
            ),
          ),
          Icon(Icons.lock_rounded, color: colors.onSurfaceVariant, size: 19),
        ],
      ),
    );
  }
}
