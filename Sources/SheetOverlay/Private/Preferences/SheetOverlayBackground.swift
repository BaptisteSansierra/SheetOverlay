//
//  SheetOverlayBackground.swift
//  Dropin
//
//  Created by baptiste sansierra on 12/3/26.
//

import SwiftUI

// Equatable AnyShapeStyle wrapper
internal struct SheetOverlayBackground: Equatable {
    let style: AnyShapeStyle
    private let id: UUID

    init<S: ShapeStyle>(_ style: S) {
        self.style = AnyShapeStyle(style)
        self.id = UUID()
    }

    static func == (lhs: SheetOverlayBackground, rhs: SheetOverlayBackground) -> Bool {
        lhs.id == rhs.id
    }
}
