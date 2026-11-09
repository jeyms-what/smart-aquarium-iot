import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'data/local/telemetry_store.dart';
import 'data/remote/telemetry_api_client.dart';
import 'data/repositories/aquarium_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localStore = await SqliteTelemetryStore.open();
  final repository = AquariumRepository(
    deviceId: AppConfig.deviceId,
    localStore: localStore,
    apiClient: TelemetryApiClient(),
  );

  runApp(SmartAquariumApp(repository: repository));
}
