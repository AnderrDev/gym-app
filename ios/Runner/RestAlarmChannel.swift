import Flutter
import Foundation

#if canImport(AlarmKit)
import ActivityKit
import AlarmKit
import SwiftUI
#endif

/// Canal mínimo hacia AlarmKit (iOS 26+) para la alarma de fin de descanso.
///
/// Runner despliega en iOS 13: esta clase NO lleva `@available`, cada método
/// comprueba `#available(iOS 26.0, *)` y delega en `RestAlarmKitImpl`. Los
/// símbolos de AlarmKit quedan weak-linkeados (comprobar con
/// `otool -l Runner | grep -A2 LC_LOAD_WEAK_DYLIB`), así que en iOS < 26 la app
/// arranca y el canal responde `unsupported` / `false`.
///
/// Contrato (canal `com.gymtracker.gym_flutter/rest_alarm`):
/// - `authorizationState` → "unsupported" | "notDetermined" | "denied" | "authorized"
/// - `requestAuthorization` → mismo enum, tras mostrar el diálogo si hace falta
/// - `schedule` {"epochMs": Double} → Bool. Cancela las alarmas previas de la
///   app y programa una alarma de fecha fija (sin cuenta atrás de AlarmKit:
///   la cuenta atrás la muestra nuestra Live Activity).
/// - `cancelAll` → nil. Detiene la que esté sonando y cancela las programadas.
final class RestAlarmChannel {
  static let channelName = "com.gymtracker.gym_flutter/rest_alarm"

  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      Self.handle(call, result: result)
    }
  }

  private static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    #if canImport(AlarmKit)
    if #available(iOS 26.0, *) {
      RestAlarmKitImpl.handle(call, result: result)
      return
    }
    #endif
    switch call.method {
    case "authorizationState", "requestAuthorization":
      result("unsupported")
    case "schedule":
      result(false)
    case "cancelAll":
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

#if canImport(AlarmKit)
/// Metadata vacía: la alarma no lleva datos propios.
@available(iOS 26.0, *)
struct RestAlarmMetadata: AlarmMetadata {}

@available(iOS 26.0, *)
enum RestAlarmKitImpl {
  /// Tono de la alarma: el mismo `.caf` de la notificación de P1 (fase
  /// Resources de Runner, raíz del bundle).
  static let soundName = "rest_alarm.caf"

  /// Azul de marca (`AppPalette.primary` claro, 0xFF0066CC).
  static let tint = Color(red: 0.0, green: 0.4, blue: 0.8)

  static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    Task {
      let value: Any?
      switch call.method {
      case "authorizationState":
        value = describe(AlarmManager.shared.authorizationState)
      case "requestAuthorization":
        value = await requestAuthorization()
      case "schedule":
        let args = call.arguments as? [String: Any]
        if let epochMs = args?["epochMs"] as? Double, epochMs.isFinite {
          value = await schedule(at: Date(timeIntervalSince1970: epochMs / 1000))
        } else {
          value = false
        }
      case "cancelAll":
        cancelAll()
        value = nil
      default:
        value = FlutterMethodNotImplemented
      }
      await MainActor.run { result(value) }
    }
  }

  private static func describe(_ state: AlarmManager.AuthorizationState) -> String {
    switch state {
    case .notDetermined: return "notDetermined"
    case .denied: return "denied"
    case .authorized: return "authorized"
    @unknown default: return "denied"
    }
  }

  private static func requestAuthorization() async -> String {
    let manager = AlarmManager.shared
    if manager.authorizationState != .notDetermined {
      return describe(manager.authorizationState)
    }
    do {
      return describe(try await manager.requestAuthorization())
    } catch {
      NSLog("[RestAlarm] requestAuthorization: \(error.localizedDescription)")
      return describe(manager.authorizationState)
    }
  }

  private static func schedule(at date: Date) async -> Bool {
    guard AlarmManager.shared.authorizationState == .authorized else { return false }
    // Una sola alarma de descanso a la vez: reprogramar = cancelar + crear.
    cancelAll()

    let title = LocalizedStringResource(stringLiteral: "¡A entrenar!")
    let alert: AlarmPresentation.Alert
    if #available(iOS 26.1, *) {
      // Desde 26.1 el botón de detener lo pone el sistema.
      alert = AlarmPresentation.Alert(title: title)
    } else {
      alert = AlarmPresentation.Alert(
        title: title,
        stopButton: AlarmButton(
          text: LocalizedStringResource(stringLiteral: "Detener"),
          textColor: .white,
          systemImageName: "stop.circle"
        )
      )
    }
    let attributes = AlarmAttributes<RestAlarmMetadata>(
      presentation: AlarmPresentation(alert: alert),
      tintColor: tint
    )
    let configuration = AlarmManager.AlarmConfiguration<RestAlarmMetadata>(
      schedule: .fixed(date),
      attributes: attributes,
      sound: .named(soundName)
    )
    do {
      _ = try await AlarmManager.shared.schedule(id: UUID(), configuration: configuration)
      return true
    } catch {
      NSLog("[RestAlarm] schedule: \(error.localizedDescription)")
      return false
    }
  }

  /// Todas las alarmas de AlarmKit de la app son de descanso, así que se
  /// cancelan todas (también las huérfanas de un proceso anterior).
  private static func cancelAll() {
    let manager = AlarmManager.shared
    guard let alarms = try? manager.alarms else { return }
    for alarm in alarms {
      if alarm.state == .alerting {
        try? manager.stop(id: alarm.id)
      }
      try? manager.cancel(id: alarm.id)
    }
  }
}
#endif
