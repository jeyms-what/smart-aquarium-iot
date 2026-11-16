import 'dart:async';

import 'package:flutter/material.dart';

import 'data/repositories/aquarium_repository.dart';
import 'features/care/fish_care_profile_store.dart';
import 'features/care/fish_care_screen.dart';
import 'widgets/glass_panel.dart';
import 'features/control/control_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/history/history_screen.dart';
import 'features/monitoring/monitoring_controller.dart';
import 'features/settings/settings_screen.dart';
import 'theme/app_theme.dart';

class SmartAquariumApp extends StatefulWidget {
  const SmartAquariumApp({super.key, this.repository, this.fishCareProfileStore});

  /// Null is used by widget previews/tests. The production entry point injects
  /// the SQLite-backed repository from main.dart.
  final AquariumRepository? repository;
  final FishCareProfileStore? fishCareProfileStore;

  @override
  State<SmartAquariumApp> createState() => _SmartAquariumAppState();
}

class _SmartAquariumAppState extends State<SmartAquariumApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  late final MonitoringController _monitoringController;
  late final FishCareProfileStore _fishCareProfileStore;

  @override
  void initState() {
    super.initState();
    _monitoringController = MonitoringController(repository: widget.repository);
    _fishCareProfileStore = widget.fishCareProfileStore ?? InMemoryFishCareProfileStore();
    unawaited(_monitoringController.initialize());
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  void dispose() {
    _monitoringController.dispose();
    unawaited(_fishCareProfileStore.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquaCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: AquariumShell(
        controller: _monitoringController,
        fishCareProfileStore: _fishCareProfileStore,
        onToggleTheme: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

class AquariumShell extends StatefulWidget {
  const AquariumShell({
    required this.controller,
    required this.fishCareProfileStore,
    required this.onToggleTheme,
    required this.isDarkMode,
    super.key,
  });

  final MonitoringController controller;
  final FishCareProfileStore fishCareProfileStore;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  @override
  State<AquariumShell> createState() => _AquariumShellState();
}

class _AquariumShellState extends State<AquariumShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardScreen(
        controller: widget.controller,
        onToggleTheme: widget.onToggleTheme,
        isDarkMode: widget.isDarkMode,
        onOpenCare: () => setState(() => _selectedIndex = 2),
      ),
      ControlScreen(repository: widget.controller.repository),
      FishCareScreen(
        controller: widget.controller,
        profileStore: widget.fishCareProfileStore,
      ),
      HistoryScreen(controller: widget.controller),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? const [Color(0xFF071A25), Color(0xFF0A2A35), Color(0xFF071A25)]
                : const [Color(0xFFEAF7F5), Color(0xFFD8F1ED), Color(0xFFF4FBFA)],
          ),
        ),
        child: SafeArea(child: IndexedStack(index: _selectedIndex, children: pages)),
      ),
      bottomNavigationBar: GlassPanel(
        padding: EdgeInsets.zero,
        radius: 24,
        child: NavigationBar(
        height: 72,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.tune_rounded), selectedIcon: Icon(Icons.tune_rounded), label: 'Control'),
          NavigationDestination(key: ValueKey('nav-care'), icon: Icon(Icons.set_meal_outlined), selectedIcon: Icon(Icons.set_meal_rounded), label: 'Care'),
          NavigationDestination(key: ValueKey('nav-history'), icon: Icon(Icons.query_stats_rounded), selectedIcon: Icon(Icons.query_stats_rounded), label: 'History'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
        ),
      ),
    );
  }
}
