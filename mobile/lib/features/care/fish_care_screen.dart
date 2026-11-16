import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/telemetry_reading.dart';
import '../../widgets/glass_panel.dart';
import '../monitoring/monitoring_controller.dart';
import 'fish_care_profile_store.dart';
import 'fish_species.dart';

class FishCareScreen extends StatefulWidget {
  const FishCareScreen({
    required this.controller,
    required this.profileStore,
    super.key,
  });

  final MonitoringController controller;
  final FishCareProfileStore profileStore;

  @override
  State<FishCareScreen> createState() => _FishCareScreenState();
}

class _FishCareScreenState extends State<FishCareScreen> {
  String? _selectedSpeciesId;
  bool _isLoadingProfile = true;
  bool _isSavingProfile = false;
  String? _profileError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final savedId = await widget.profileStore.loadSelectedSpeciesId();
      if (!mounted) return;
      setState(() {
        _selectedSpeciesId = fishSpeciesById(savedId)?.id;
        _isLoadingProfile = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _profileError = 'Could not load the saved fish profile: $error';
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _selectSpecies(String? speciesId) async {
    if (speciesId == null) return;
    setState(() {
      _selectedSpeciesId = speciesId;
      _isSavingProfile = true;
      _profileError = null;
    });
    try {
      await widget.profileStore.saveSelectedSpeciesId(speciesId);
    } catch (error) {
      if (mounted) {
        setState(() => _profileError = 'Profile could not be saved: $error');
      }
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  void _copySource(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Care guide URL copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Fish care'),
        titleSpacing: 20,
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final snapshot = widget.controller.snapshot;
          final species = fishSpeciesById(_selectedSpeciesId);
          final temperature = species?.assessTemperature(
            snapshot.readingFor('water_temperature'),
          );
          final phReading = snapshot.readingFor('water_ph') ??
              snapshot.readingFor('ph');
          final ph = species?.assessPh(phReading);

          return ListView(
            key: const ValueKey('fish-care-scroll-view'),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
            children: [
              Text(
                'PERSONALIZED CARE',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 10,
                  letterSpacing: 1.7,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Care for your fish',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose the species in your aquarium to compare available readings with published care-sheet guidance.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.set_meal_outlined),
                          SizedBox(width: 9),
                          Text(
                            'Aquarium species profile',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_isLoadingProfile)
                        const LinearProgressIndicator()
                      else
                        DropdownButtonFormField<String>(
                          key: const ValueKey('fish-species-selector'),
                          initialValue: _selectedSpeciesId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Fish species',
                            border: OutlineInputBorder(),
                          ),
                          hint: const Text('Choose your fish species'),
                          items: [
                            for (final item in fishSpeciesCatalog)
                              DropdownMenuItem(
                                value: item.id,
                                child: Text(
                                  '${item.commonName} · ${item.scientificName}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: _isSavingProfile ? null : _selectSpecies,
                        ),
                      if (_isSavingProfile) ...[
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(),
                      ],
                      if (_profileError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _profileError!,
                          style: TextStyle(color: colors.error, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (species == null && !_isLoadingProfile) ...[
                const SizedBox(height: 14),
                const _InformationPanel(
                  icon: Icons.info_outline_rounded,
                  title: 'Select a species to begin',
                  message:
                      'AquaCare will use this profile to show species-specific temperature, pH, habitat, feeding, and water-quality guidance. The selection is saved on this phone.',
                ),
              ],
              if (species != null) ...[
                const SizedBox(height: 14),
                _SpeciesOverview(species: species),
                const SizedBox(height: 18),
                _SectionLabel(
                  title: 'Measured water conditions',
                  subtitle: 'Compared with the selected species guide',
                ),
                const SizedBox(height: 10),
                _CareRangeCard(
                  title: 'Water temperature',
                  icon: Icons.thermostat_rounded,
                  current: temperature!,
                  recommendedRange: species.temperatureRange,
                ),
                const SizedBox(height: 10),
                _CareRangeCard(
                  title: 'pH',
                  icon: Icons.science_outlined,
                  current: ph!,
                  recommendedRange: species.phRange,
                ),
                const SizedBox(height: 12),
                const _InformationPanel(
                  icon: Icons.rule_rounded,
                  title: 'Guideline, not a diagnosis',
                  message:
                      'An outside-range result is a prompt to verify the reading and investigate gradually. Do not make rapid temperature or pH changes. These ranges are care-guide recommendations, not lethal limits or veterinary thresholds.',
                ),
                const SizedBox(height: 18),
                _SectionLabel(
                  title: 'Species care recommendations',
                  subtitle: 'Practical care notes for this fish',
                ),
                const SizedBox(height: 10),
                _RecommendationCard(
                  icon: Icons.home_work_outlined,
                  title: 'Habitat and aquarium',
                  message: species.habitatCare,
                ),
                _RecommendationCard(
                  icon: Icons.groups_2_outlined,
                  title: 'Behavior and tank mates',
                  message: species.socialCare,
                ),
                _RecommendationCard(
                  icon: Icons.restaurant_outlined,
                  title: 'Feeding',
                  message: species.feedingCare,
                ),
                _RecommendationCard(
                  icon: Icons.water_drop_outlined,
                  title: 'Water quality',
                  message: species.waterQualityCare,
                ),
                const SizedBox(height: 18),
                _SectionLabel(
                  title: 'Measurements still needed',
                  subtitle: 'Not measured by the current connected sensor set',
                ),
                const SizedBox(height: 10),
                const _InformationPanel(
                  icon: Icons.science_outlined,
                  title: 'Test these manually',
                  message:
                      'Ammonia and nitrite should be tested with an aquarium water test kit; the care sheets specify 0 mg/L. Nitrate and water hardness (GH/KH) also need appropriate test kits. TDS is not a substitute for pH, ammonia, nitrite, nitrate, GH, or KH.',
                ),
                const SizedBox(height: 18),
                _SourceCard(
                  sourceName: species.sourceName,
                  sourceNote: species.sourceNote,
                  sourceUrl: species.sourceUrl,
                  onCopy: () => _copySource(species.sourceUrl),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SpeciesOverview extends StatelessWidget {
  const _SpeciesOverview({required this.species});

  final FishSpeciesCare species;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.set_meal_rounded, color: colors.primary, size: 25),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      species.commonName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      species.scientificName,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _GuidelineChip(
                label: 'Temperature ${species.temperatureRange}',
              ),
              _GuidelineChip(label: 'pH ${species.phRange}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
        ),
      ],
    );
  }
}

class _CareRangeCard extends StatelessWidget {
  const _CareRangeCard({
    required this.title,
    required this.icon,
    required this.current,
    required this.recommendedRange,
  });

  final String title;
  final IconData icon;
  final CareRangeAssessment current;
  final String recommendedRange;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (color, statusIcon) = switch (current.status) {
      CareRangeStatus.withinGuideline => (const Color(0xFF48C49A), Icons.check_circle_outline),
      CareRangeStatus.belowGuideline ||
      CareRangeStatus.aboveGuideline => (const Color(0xFFE9B45C), Icons.warning_amber_rounded),
      CareRangeStatus.invalid ||
      CareRangeStatus.stale => (colors.error, Icons.error_outline_rounded),
      _ => (colors.onSurfaceVariant, Icons.remove_circle_outline_rounded),
    };
    final valueText = current.value == null
        ? '—'
        : '${current.value!.toStringAsFixed(title == 'pH' ? 2 : 1)} ${current.unit ?? ''}';
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.primary, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              Icon(statusIcon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  valueText,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Text(
                'Guide: $recommendedRange',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            current.label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
          ),
          const SizedBox(height: 3),
          Text(
            current.detail,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: GlassPanel(
        padding: const EdgeInsets.all(14),
        radius: 18,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.primary, size: 21),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 5),
                  Text(message, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InformationPanel extends StatelessWidget {
  const _InformationPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      radius: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary, size: 21),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                const SizedBox(height: 5),
                Text(message, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidelineChip extends StatelessWidget {
  const _GuidelineChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colors.primary.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.sourceName,
    required this.sourceNote,
    required this.sourceUrl,
    required this.onCopy,
  });

  final String sourceName;
  final String sourceNote;
  final String sourceUrl;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Care guide source', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          const SizedBox(height: 5),
          Text(sourceName, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 5),
          Text(sourceNote, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10, height: 1.45)),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: Text(
                  sourceUrl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.primary, fontSize: 9),
                ),
              ),
              IconButton(
                tooltip: 'Copy care guide URL',
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
