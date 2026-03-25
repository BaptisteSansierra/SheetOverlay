//
//  SheetOverlayKeyboardPolicy.swift
//  SheetOverlay
//
//  Created by baptiste sansierra on 25/3/26.
//

import Foundation

public enum SheetOverlayKeyboardPolicy: Sendable, Equatable, Hashable {
    case ignore
    case maxOffset(_ height: CGFloat)
    case fullOffset
}

