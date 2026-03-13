//
//  SheetOverlayPreferences.swift
//  Dropin
//
//  Created by baptiste sansierra on 12/3/26.
//

import SwiftUI

internal struct SheetOverlayDetentsPreferenceKey: PreferenceKey {
    static let defaultValue: [SheetOverlayDetent] = [.medium]
    static func reduce(value: inout [SheetOverlayDetent], nextValue: () -> [SheetOverlayDetent]) {
        value = nextValue()
    }
}

internal struct SheetOverlayBackgroundPreferenceKey: PreferenceKey {
    static let defaultValue: SheetOverlayBackground = SheetOverlayBackground(.thinMaterial)
    static func reduce(value: inout SheetOverlayBackground, nextValue: () -> SheetOverlayBackground) {
        value = nextValue()
    }
}

internal struct SheetOverlayDragIndicatorPreferenceKey: PreferenceKey {
    static let defaultValue: Visibility = .automatic
    static func reduce(value: inout Visibility, nextValue: () -> Visibility) {
        value = nextValue()
    }
}

internal struct SheetOverlayCornerRadiusPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 20
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

internal struct SheetOverlayShadowPreferenceKey: PreferenceKey {
    static let defaultValue: SheetOverlayShadowConfig = .default
    static func reduce(value: inout SheetOverlayShadowConfig, nextValue: () -> SheetOverlayShadowConfig) {
        value = nextValue()
    }
}
