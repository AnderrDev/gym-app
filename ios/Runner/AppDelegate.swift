import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  /// Alarma de fin de descanso con AlarmKit (iOS 26+). Se retiene aquí para
  /// que el handler del canal viva lo mismo que la app.
  private var restAlarmChannel: RestAlarmChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = self.registrar(forPlugin: "RestAlarmChannel") {
      restAlarmChannel = RestAlarmChannel(messenger: registrar.messenger())
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
