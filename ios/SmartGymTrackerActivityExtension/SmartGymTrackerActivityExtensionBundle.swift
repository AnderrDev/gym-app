//
//  SmartGymTrackerActivityExtensionBundle.swift
//  SmartGymTrackerActivityExtension
//
//  Bundle del widget extension. Sólo registramos la Live Activity — el
//  homescreen widget y el Control widget (iOS 18+) del template autogenerado
//  no se usan para este feature.
//

import WidgetKit
import SwiftUI

@main
struct SmartGymTrackerActivityExtensionBundle: WidgetBundle {
    var body: some Widget {
        SmartGymTrackerActivityExtensionLiveActivity()
    }
}
