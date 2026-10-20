// Flujos de punta a punta (app real + backend en memoria) bajo
// `flutter test`, sin dispositivo. Los mismos flujos corren en un
// dispositivo con `flutter test integration_test/app_flows_test.dart`.
import '../../integration_test/flows/app_flows.dart';

void main() => appFlows();
