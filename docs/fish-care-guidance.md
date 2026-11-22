# Species-specific fish care guidance

## Scope

The Flutter Care screen provides offline starter profiles for Betta, Neon Tetra, Goldfish, and Guppy. A user must select a species; the app does not assume which fish the aquarium contains. The selected species ID is stored locally in a separate SQLite database.

The planned AquaCare sensor set is:
- TDS using sensor code `tds` (or `total_dissolved_solids`), reported in ppm only after calibration.
- Turbidity using sensor code `turbidity`; raw ADC must not be labelled as NTU without a calibration method.
- Water level using sensor code `water_level`.
- pH using sensor code `ph` or `water_ph`.
- Water temperature using sensor code `water_temperature` and supported Celsius/Fahrenheit units.

Species-specific range assessments currently use only water temperature and pH. TDS, turbidity, and water level are shown as measurements and are not used to infer ammonia, nitrite, nitrate, GH/KH, or overall water safety.

The assessment is intentionally conservative:
- Missing, invalid, stale, unsupported-unit, or unverified-time readings are not reported as within range.
- A measurement outside a published guideline is described as below or above the guide range. It is not called critical, toxic, lethal, or an emergency.
- The guidance ranges are care-sheet recommendations, not lethal limits, veterinary thresholds, or a substitute for expert advice.
- Do not make rapid changes to pH or temperature to chase a target value.
- TDS is not a substitute for pH, ammonia, nitrite, nitrate, or GH/KH testing.
- The current hardware does not measure ammonia, nitrite, nitrate, GH, or KH. These require appropriate aquarium test kits.

## Starter profiles and references

| Profile | Temperature guidance | pH guidance | Source and important qualification |
|---|---:|---:|---|
| Betta (*Betta splendens*) | 20–28 °C | 6.0–8.0 | OATA tank-reared Betta care sheet. Less common Betta species can differ. |
| Neon tetra (*Paracheirodon innesi*) | 22–27 °C | 6.5–8.0 | OATA guidance for captive-bred tetras as a group, not a neon-tetra-specific tolerance study. Confirm exact requirements with a species specialist. |
| Goldfish (*Carassius auratus*) | 4–25 °C | 6.0–8.0 | Broad OATA goldfish guidance. Fancy and other varieties can have narrower practical preferences. |
| Guppy (*Poecilia reticulata*) | 20–28 °C | 7.0–8.0 | OATA guppy and molly guidance. OATA also gives medium-hard water guidance (GH 8–18 °dH; KH 5–15 °dKH). |

References:
- OATA, [How to look after Siamese fighting fish (Bettas)](https://ornamentalfish.org/what-we-do/advice-information/care-sheets/caresheets-tropical-freshwater-fish/how-to-look-after-siamese-fighting-fish-bettas/)
- OATA, [How to look after tetras and pencilfish](https://ornamentalfish.org/what-we-do/advice-information/care-sheets/caresheets-tropical-freshwater-fish/how-to-look-after-tetras-and-pencilfish/)
- OATA, [How to look after goldfish in an aquarium](https://ornamentalfish.org/what-we-do/advice-information/care-sheets/caresheets-coldwater-fish/how-to-look-after-goldfish-in-an-aquarium-fishtank/)
- OATA, [How to look after guppies and mollies](https://ornamentalfish.org/what-we-do/advice-information/care-sheets/caresheets-tropical-freshwater-fish/how-to-look-after-guppies-and-mollies/)

## Use in the app

1. Open the **Care** tab or the dashboard's species-care entry.
2. Select the species actually kept in the aquarium.
3. The selection is saved on the phone using `aquacare_fish_care.db`.
4. Connect valid sensor telemetry to compare temperature and pH against the selected guide.
5. Read the habitat, behavior, feeding, and water-quality notes and follow the linked source guide.

If the aquarium contains multiple species, do not assume that one profile represents the whole tank. Multi-species compatibility and conflicting water requirements require a separate stocking-profile feature. No compatibility verdict is currently generated.

## Verification

Automated tests cover:
- Temperature inside the guideline.
- Fahrenheit-to-Celsius conversion.
- Missing pH data.
- Stale telemetry.
- Uptime-only/unverified device timestamps.
- The qualification attached to the Neon Tetra group-level guide.

A successful code test does not verify the sensor calibration or the real aquarium's water chemistry. Physical sensor calibration and manual water-test validation remain separate acceptance activities.
