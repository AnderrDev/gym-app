//
//  SmartGymTrackerActivityExtensionControl.swift
//  SmartGymTrackerActivityExtension
//
//  Stub iOS 18+ del template autogenerado. No lo registramos en el bundle —
//  vive acá sólo para que el target compile contra iOS 16.1+ sin tener que
//  borrarlo a mano desde Xcode.
//

import AppIntents
import SwiftUI
import WidgetKit

@available(iOS 18.0, *)
struct SmartGymTrackerActivityExtensionControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.gymtracker.gymFlutter.SmartGymTrackerActivityExtension",
            provider: Provider()
        ) { value in
            ControlWidgetToggle(
                "Start Timer",
                isOn: value,
                action: StartTimerIntent()
            ) { isRunning in
                Label(isRunning ? "On" : "Off", systemImage: "timer")
            }
        }
        .displayName("Timer")
        .description("A an example control that runs a timer.")
    }
}

@available(iOS 18.0, *)
extension SmartGymTrackerActivityExtensionControl {
    struct Provider: ControlValueProvider {
        var previewValue: Bool { false }
        func currentValue() async throws -> Bool { true }
    }
}

@available(iOS 18.0, *)
struct StartTimerIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Start a timer"

    @Parameter(title: "Timer is running")
    var value: Bool

    func perform() async throws -> some IntentResult { .result() }
}
