// Driver de `integration_test/app_flows_test.dart`: además del resultado,
// guarda en `build/integration_response_data.json` el motivo de cada flujo
// que falla y, con `--dart-define=FLOW_SCREENSHOTS=true`, una captura en
// `build/flow_screenshots/`.
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
  writeResponseOnFailure: true,
  onScreenshot: (name, bytes, [args]) async {
    File('build/flow_screenshots/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);
    return true;
  },
);
