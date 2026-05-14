//
//  SmartGymTrackerActivityExtensionLiveActivity.swift
//  SmartGymTrackerActivityExtension
//
//  Live Activity para sesión de entrenamiento activa. La arquitectura sigue
//  la convención del plugin `live_activities` (Pinkfish): el plugin maneja
//  el `Activity<LiveActivitiesAppAttributes>` con un solo campo `id: UUID`
//  como Attributes; el payload real viaja vía `UserDefaults(suiteName:
//  appGroupId)` con keys prefijadas `<uuid>_<keyName>`.
//

import ActivityKit
import WidgetKit
import SwiftUI

/// El Attributes struct DEBE llamarse `LiveActivitiesAppAttributes` y tener
/// esta forma exacta — el plugin lo referencia hardcoded. No agregar campos
/// custom acá.
struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
    public typealias LiveDeliveryData = ContentState

    public struct ContentState: Codable, Hashable {}

    var id = UUID()
}

extension LiveActivitiesAppAttributes {
    /// El plugin escribe cada key del payload Dart con este prefijo:
    /// `<uuid>_<keyName>`. Usamos lo mismo para leer.
    func prefixedKey(_ key: String) -> String {
        return "\(id)_\(key)"
    }
}

/// `UserDefaults` compartido con el app principal vía App Group. El bundle
/// del Widget Extension hereda el entitlement `application-groups` que
/// agregamos en Xcode.
private let sharedDefaults = UserDefaults(
    suiteName: "group.com.gymtracker.gym_flutter"
)!

struct SmartGymTrackerActivityExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            let data = WorkoutData(attributes: context.attributes)
            LockScreenView(data: data)
                .activityBackgroundTint(Color.black.opacity(0.55))
                .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            let data = WorkoutData(attributes: context.attributes)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title3)
                        .foregroundColor(data.isResting ? .orange : .yellow)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ChronoText(data: data)
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(data.dayName.uppercased())
                            .font(.caption.weight(.bold))
                            .tracking(1.4)
                            .foregroundColor(.gray)
                        Text(data.isResting
                             ? "Descanso en curso"
                             : "\(data.completedSets)/\(data.totalSets) series")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(data.isResting ? .orange : .white)
                    }
                }
            } compactLeading: {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(data.isResting ? .orange : .yellow)
            } compactTrailing: {
                ChronoText(data: data, showsHours: false)
                    .monospacedDigit()
                    .frame(maxWidth: 56)
            } minimal: {
                Text("\(data.completedSets)/\(data.totalSets)")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Data adapter

/// Lee el payload del workout desde `UserDefaults` compartido. Cada campo lo
/// escribió el plugin con la key `<activityUUID>_<keyName>`.
private struct WorkoutData {
    let dayName: String
    let completedSets: Int
    let totalSets: Int
    let sessionStartedAt: Date
    let restEndsAt: Date?

    init(attributes: LiveActivitiesAppAttributes) {
        dayName = sharedDefaults.string(forKey: attributes.prefixedKey("dayName"))
            ?? "Entrenamiento"
        completedSets = Self.readInt(forKey: attributes.prefixedKey("completedSets"))
        totalSets = Self.readInt(forKey: attributes.prefixedKey("totalSets"))
        sessionStartedAt = Self.readDate(
            forKey: attributes.prefixedKey("sessionStartedAtMs"),
            fallback: Date()
        )
        restEndsAt = Self.readOptionalDate(
            forKey: attributes.prefixedKey("restEndsAtMs")
        )
    }

    var isResting: Bool { restEndsAt != nil }

    /// Acepta tanto Int como String (`Int.init(_:)`) — el plugin a veces
    /// serializa números a String cuando viajan por el channel.
    private static func readInt(forKey key: String) -> Int {
        if let s = sharedDefaults.string(forKey: key), let n = Int(s) {
            return n
        }
        return sharedDefaults.integer(forKey: key)
    }

    private static func readDate(forKey key: String, fallback: Date) -> Date {
        if let s = sharedDefaults.string(forKey: key), let ms = Double(s) {
            return Date(timeIntervalSince1970: ms / 1000.0)
        }
        let raw = sharedDefaults.double(forKey: key)
        return raw == 0 ? fallback : Date(timeIntervalSince1970: raw / 1000.0)
    }

    private static func readOptionalDate(forKey key: String) -> Date? {
        if let s = sharedDefaults.string(forKey: key), let ms = Double(s) {
            return Date(timeIntervalSince1970: ms / 1000.0)
        }
        let raw = sharedDefaults.double(forKey: key)
        return raw == 0 ? nil : Date(timeIntervalSince1970: raw / 1000.0)
    }
}

// MARK: - Views

private struct ChronoText: View {
    let data: WorkoutData
    var showsHours: Bool = true

    var body: some View {
        if let restEnd = data.restEndsAt {
            // Countdown del descanso: por default `countsDown: true` cuenta
            // hacia el final del rango — exactamente lo que queremos.
            Text(timerInterval: Date()...restEnd, countsDown: true)
                .foregroundColor(.orange)
        } else {
            // Workout en curso: contamos HACIA ADELANTE desde sessionStartedAt.
            // CRÍTICO: `countsDown: false`. El default (true) mostraría el
            // tiempo restante hasta `distantFuture` (~1975 años → "17309283:5:10").
            Text(timerInterval: data.sessionStartedAt...Date.distantFuture,
                 countsDown: false,
                 showsHours: showsHours)
                .foregroundColor(.white)
        }
    }
}

private struct LockScreenView: View {
    let data: WorkoutData

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                    .foregroundColor(data.isResting ? .orange : .yellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text(data.isResting ? "DESCANSO" : "ENTRENANDO")
                        .font(.caption2.weight(.heavy))
                        .tracking(1.6)
                        .foregroundColor(data.isResting ? .orange : .gray)
                    Text(data.dayName)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                Spacer()
                ChronoText(data: data)
                    .font(.title2.weight(.bold))
                    .monospacedDigit()
            }

            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.footnote)
                Text("\(data.completedSets)/\(data.totalSets) series")
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
