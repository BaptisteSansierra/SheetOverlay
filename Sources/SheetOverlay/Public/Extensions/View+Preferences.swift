//
//  View+Preferences.swift
//  Dropin
//
//  Created by baptiste sansierra on 12/3/26.
//

import SwiftUI

public extension View {
    
    func sheetOverlayDetents(_ detents: [SheetOverlayDetent]) -> some View {
        preference(
            key: SheetOverlayDetentsPreferenceKey.self,
            value: detents
        )
    }
    
    func sheetOverlayBackground<Value: ShapeStyle>(_ background: Value) -> some View {
        preference(
            key: SheetOverlayBackgroundPreferenceKey.self,
            value: SheetOverlayBackground(background)
        )
    }
    
    func sheetOverlayDragIndicator(_ visibility: Visibility) -> some View {
        preference(
            key: SheetOverlayDragIndicatorPreferenceKey.self,
            value: visibility
        )
    }
    
    func sheetOverlayCornerRadius(_ cornerRadius: CGFloat) -> some View {
        preference(
            key: SheetOverlayCornerRadiusPreferenceKey.self,
            value: cornerRadius
        )
    }

    func sheetOverlayShadow(color: Color = Color(.sRGBLinear, white: 0, opacity: 0.33),
                            radius: CGFloat,
                            x: CGFloat = 0,
                            y: CGFloat = 0) -> some View {
        preference(
            key: SheetOverlayShadowPreferenceKey.self,
            value: SheetOverlayShadowConfig(color: color, radius: radius, offset: CGSize(width: x, height: y))
        )
    }

    func sheetOverlayHideShadow() -> some View {
        preference(
            key: SheetOverlayShadowPreferenceKey.self,
            value: SheetOverlayShadowConfig.none
        )
    }
    
    func sheetOverlayKeyboardPolicy(_ policy: SheetOverlayKeyboardPolicy) -> some View {
        preference(
            key: SheetOverlayKeyboardPolicyPreferenceKey.self,
            value: policy
        )
    }
}
