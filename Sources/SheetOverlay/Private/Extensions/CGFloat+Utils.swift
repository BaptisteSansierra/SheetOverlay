//
//  CGFloat+utils.swift
//  SheetOverlay
//
//  Created by baptiste sansierra on 12/3/26.
//

import Foundation

extension CGFloat {
    
    mutating func clamped(min: CGFloat, max: CGFloat) {
        let clamped = self < min ? min : ( self > max ? max : self )
        self = clamped
    }
    
    func clamp(min: CGFloat, max: CGFloat) -> CGFloat {
        return self < min ? min : ( self > max ? max : self )
    }
    
    var checked: CGFloat {
        assert(self.isFinite, "Invalid CGFloat: \(self)")
        return self
    }
}
