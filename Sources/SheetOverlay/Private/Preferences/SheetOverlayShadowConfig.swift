//
//  SheetOverlayShadowConfig.swift
//  Dropin
//
//  Created by baptiste sansierra on 12/3/26.
//

import SwiftUI

internal struct SheetOverlayShadowConfig: Sendable, Equatable {
    public let color: Color
    public let radius: CGFloat
    public let offset: CGSize

    static public var none: SheetOverlayShadowConfig {
        .init(color: .clear, radius: 0, offset: .zero)
    }

    static public var `default`: SheetOverlayShadowConfig {
        .init(color: Color(.sRGBLinear, white: 0, opacity: 0.33), radius: 5, offset: .zero)
    }
}
