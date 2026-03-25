//
//  SheetOverlayDetent.swift
//  Dropin
//
//  Created by baptiste sansierra on 10/3/26.
//

import Foundation

public enum SheetOverlayDetent: Sendable, Equatable, Hashable {
    case medium
    case large
    case fraction(_ fraction: CGFloat)
    case height(_ height: CGFloat)
}
