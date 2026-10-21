// Flujos de punta a punta en un dispositivo real, con el backend en
// memoria (sin Supabase ni credenciales):
//   flutter test integration_test/app_flows_test.dart -d macos
import 'package:integration_test/integration_test.dart';

import 'flows/app_flows.dart';

/// `--dart-define=FLOW_SCREENSHOTS=true` guarda una captura de cada fallo
/// (necesita un driver con `onScreenshot`).
const _screenshots = bool.fromEnvironment('FLOW_SCREENSHOTS');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  onFlowFailure = (flow, error) async {
    (binding.reportData ??= <String, dynamic>{})[flow] = error;
    if (_screenshots) {
      try {
        await binding.takeScreenshot(flow.replaceAll(RegExp(r'\W+'), '_'));
      } catch (_) {}
    }
  };
  appFlows();
}
