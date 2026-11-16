import '../../data/models/telemetry_reading.dart';

enum CareRangeStatus {
  withinGuideline,
  belowGuideline,
  aboveGuideline,
  notMeasured,
  invalid,
  stale,
  timeUnverified,
  unsupportedUnit,
}

class CareRangeAssessment {
  const CareRangeAssessment({
    required this.status,
    required this.label,
    required this.detail,
    this.value,
    this.unit,
  });

  final CareRangeStatus status;
  final String label;
  final String detail;
  final double? value;
  final String? unit;

  bool get isOutsideGuideline =>
      status == CareRangeStatus.belowGuideline ||
      status == CareRangeStatus.aboveGuideline;

  static CareRangeAssessment evaluate({
    required TelemetryReading? reading,
    required String sensorCode,
    required double minimum,
    required double maximum,
    required String unit,
    bool convertTemperature = false,
  }) {
    if (reading == null) {
      return CareRangeAssessment(
        status: CareRangeStatus.notMeasured,
        label: 'Not measured',
        detail: 'No reading is available from this sensor.',
        unit: unit,
      );
    }
    if (!reading.hasUsableValue) {
      return CareRangeAssessment(
        status: CareRangeStatus.invalid,
        label: 'Invalid reading',
        detail: 'The latest sensor record is invalid or has no numeric value.',
        unit: unit,
      );
    }
    if (reading.isStale()) {
      return CareRangeAssessment(
        status: CareRangeStatus.stale,
        label: 'Stale reading',
        detail: 'Refresh telemetry before using this value for a care assessment.',
        value: reading.value,
        unit: unit,
      );
    }
    if (reading.timeQuality == 'uptime_only' ||
        reading.measuredAt.toLocal().isAfter(
          DateTime.now().add(const Duration(minutes: 1)),
        )) {
      return CareRangeAssessment(
        status: CareRangeStatus.timeUnverified,
        label: 'Time not verified',
        detail: 'The device timestamp cannot confirm how recent this reading is.',
        value: reading.value,
        unit: unit,
      );
    }
    if (reading.sensorCode != sensorCode) {
      return CareRangeAssessment(
        status: CareRangeStatus.notMeasured,
        label: 'Not measured',
        detail: 'The expected sensor channel is not available.',
        unit: unit,
      );
    }

    var value = reading.value!;
    if (convertTemperature) {
      final normalizedUnit = reading.unit.trim().toLowerCase();
      if (normalizedUnit == 'degf' ||
          normalizedUnit == '°f' ||
          normalizedUnit == 'f' ||
          normalizedUnit == 'fahrenheit') {
        value = (value - 32) * 5 / 9;
      } else if (normalizedUnit != 'degc' &&
          normalizedUnit != '°c' &&
          normalizedUnit != 'c' &&
          normalizedUnit != 'celsius') {
        return CareRangeAssessment(
          status: CareRangeStatus.unsupportedUnit,
          label: 'Unsupported unit',
          detail: 'Temperature must be reported in °C or °F.',
          value: value,
          unit: reading.unit,
        );
      }
    }

    final status = value < minimum
        ? CareRangeStatus.belowGuideline
        : value > maximum
            ? CareRangeStatus.aboveGuideline
            : CareRangeStatus.withinGuideline;

    return CareRangeAssessment(
      status: status,
      label: switch (status) {
        CareRangeStatus.withinGuideline => 'Within guideline',
        CareRangeStatus.belowGuideline => 'Below guideline',
        CareRangeStatus.aboveGuideline => 'Above guideline',
        _ => 'Not assessed',
      },
      detail: switch (status) {
        CareRangeStatus.withinGuideline =>
          'The measured value is inside this care guide range.',
        CareRangeStatus.belowGuideline =>
          'The measured value is below this care guide range.',
        CareRangeStatus.aboveGuideline =>
          'The measured value is above this care guide range.',
        _ => 'The measurement could not be assessed.',
      },
      value: value,
      unit: unit,
    );
  }
}

class FishSpeciesCare {
  const FishSpeciesCare({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.temperatureMinC,
    required this.temperatureMaxC,
    required this.phMin,
    required this.phMax,
    required this.socialCare,
    required this.habitatCare,
    required this.feedingCare,
    required this.waterQualityCare,
    required this.sourceName,
    required this.sourceUrl,
    required this.sourceNote,
  });

  final String id;
  final String commonName;
  final String scientificName;
  final double temperatureMinC;
  final double temperatureMaxC;
  final double phMin;
  final double phMax;
  final String socialCare;
  final String habitatCare;
  final String feedingCare;
  final String waterQualityCare;
  final String sourceName;
  final String sourceUrl;
  final String sourceNote;

  String get temperatureRange =>
      '${temperatureMinC.toStringAsFixed(0)}–${temperatureMaxC.toStringAsFixed(0)} °C';

  String get phRange =>
      '${phMin.toStringAsFixed(1)}–${phMax.toStringAsFixed(1)}';

  CareRangeAssessment assessTemperature(TelemetryReading? reading) =>
      CareRangeAssessment.evaluate(
        reading: reading,
        sensorCode: 'water_temperature',
        minimum: temperatureMinC,
        maximum: temperatureMaxC,
        unit: '°C',
        convertTemperature: true,
      );

  CareRangeAssessment assessPh(TelemetryReading? reading) {
    if (reading != null &&
        (reading.sensorCode == 'ph' || reading.sensorCode == 'water_ph')) {
      return CareRangeAssessment.evaluate(
        reading: reading,
        sensorCode: reading.sensorCode,
        minimum: phMin,
        maximum: phMax,
        unit: 'pH',
      );
    }
    return const CareRangeAssessment(
      status: CareRangeStatus.notMeasured,
      label: 'Not measured',
      detail: 'No pH telemetry is available. The TDS sensor cannot provide a pH measurement.',
      unit: 'pH',
    );
  }
}

/// Starter profiles use published care-sheet guidance, not lethal limits or
/// veterinary thresholds. Always verify the exact fish variety and source.
const fishSpeciesCatalog = <FishSpeciesCare>[
  FishSpeciesCare(
    id: 'betta_splendens',
    commonName: 'Betta',
    scientificName: 'Betta splendens',
    temperatureMinC: 20,
    temperatureMaxC: 28,
    phMin: 6.0,
    phMax: 8.0,
    socialCare:
        'Adult male bettas are territorial and should not be housed together. Choose tank mates carefully; individual temperament varies.',
    habitatCare:
        'Provide a secure lid, cover and resting places, stable heated water, and gentle flow. A larger, filtered aquarium is more stable than a small bowl.',
    feedingCare:
        'Use a quality betta-specific carnivorous pellet as a staple, with suitable frozen or live invertebrate foods as variety. Feed small portions and remove uneaten food.',
    waterQualityCare:
        'Test ammonia and nitrite regularly; both should be 0 mg/L. Keep water stable and avoid sudden pH or temperature changes.',
    sourceName: 'OATA — Siamese fighting fish (Bettas)',
    sourceUrl:
        'https://ornamentalfish.org/what-we-do/advice-information/care-sheets/caresheets-tropical-freshwater-fish/how-to-look-after-siamese-fighting-fish-bettas/',
    sourceNote:
        'Ranges are OATA guidance for tank-reared bettas. Less common Betta species may have different requirements.',
  ),
  FishSpeciesCare(
    id: 'neon_tetra',
    commonName: 'Neon tetra',
    scientificName: 'Paracheirodon innesi',
    temperatureMinC: 22,
    temperatureMaxC: 27,
    phMin: 6.5,
    phMax: 8.0,
    socialCare:
        'Keep as a shoaling group; OATA advises groups of at least six for tetras. Avoid mixing with fish large enough to eat them.',
    habitatCare:
        'Provide a mature, stable freshwater aquarium with plants or other cover and open swimming space. Acclimate gradually.',
    feedingCare:
        'Offer small tropical-fish foods in varied suitable forms. Ensure food is small enough for their mouths and avoid overfeeding.',
    waterQualityCare:
        'Maintain good filtration and stable water chemistry. Test ammonia and nitrite; both should be 0 mg/L.',
    sourceName: 'OATA — Tetras and pencilfish care sheet',
    sourceUrl:
        'https://ornamentalfish.org/what-we-do/advice-information/care-sheets/caresheets-tropical-freshwater-fish/how-to-look-after-tetras-and-pencilfish/',
    sourceNote:
        'Temperature and pH values are OATA guidance for captive-bred tetras as a group, not a neon-tetra-specific tolerance study. Confirm with a species specialist.',
  ),
  FishSpeciesCare(
    id: 'goldfish',
    commonName: 'Goldfish',
    scientificName: 'Carassius auratus',
    temperatureMinC: 4,
    temperatureMaxC: 25,
    phMin: 6.0,
    phMax: 8.0,
    socialCare:
        'Goldfish are social, but companions must be compatible in size, swimming ability, and water requirements. Do not mix very different-sized varieties without expert advice.',
    habitatCare:
        'Never keep goldfish in bowls or tiny unfiltered containers. They grow large and produce substantial waste; provide a spacious, strongly filtered aquarium.',
    feedingCare:
        'Feed a suitable goldfish staple in modest portions. Remove uneaten food and avoid overfeeding; adapt food form to the variety and its swimming ability.',
    waterQualityCare:
        'Goldfish need effective filtration and regular testing. Ammonia and nitrite should be 0 mg/L. Avoid rapid temperature or chemistry changes.',
    sourceName: 'OATA — Goldfish in an aquarium',
    sourceUrl:
        'https://ornamentalfish.org/what-we-do/advice-information/care-sheets/caresheets-coldwater-fish/how-to-look-after-goldfish-in-an-aquarium-fishtank/',
    sourceNote:
        'This is the broad OATA goldfish guideline. Fancy goldfish and other varieties can have narrower practical preferences; check the specific variety.',
  ),
  FishSpeciesCare(
    id: 'guppy',
    commonName: 'Guppy',
    scientificName: 'Poecilia reticulata',
    temperatureMinC: 20,
    temperatureMaxC: 28,
    phMin: 7.0,
    phMax: 8.0,
    socialCare:
        'Guppies are generally peaceful and social. Plan stocking carefully because mixed-sex groups can reproduce quickly; provide space and avoid fin-nipping tank mates.',
    habitatCare:
        'Provide a filtered, planted aquarium with swimming space and a gentle current. OATA suggests at least 45 litres for a small group of smaller livebearers.',
    feedingCare:
        'Use a quality small tropical/livebearer food and vary the diet with suitable vegetable and protein-rich foods. Feed small amounts that are eaten promptly.',
    waterQualityCare:
        'Guppies generally prefer medium-hard to hard water. OATA lists general hardness 8–18 °dH and carbonate hardness 5–15 °dKH. Ammonia and nitrite should be 0 mg/L.',
    sourceName: 'OATA — Guppies and mollies',
    sourceUrl:
        'https://ornamentalfish.org/what-we-do/advice-information/care-sheets/caresheets-tropical-freshwater-fish/how-to-look-after-guppies-and-mollies/',
    sourceNote:
        'Ranges and water-hardness guidance are OATA recommendations for guppies and mollies. Individual strains and local water conditions can differ.',
  ),
];

FishSpeciesCare? fishSpeciesById(String? id) {
  if (id == null) return null;
  for (final species in fishSpeciesCatalog) {
    if (species.id == id) return species;
  }
  return null;
}
