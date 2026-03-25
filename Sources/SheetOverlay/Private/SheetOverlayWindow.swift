//
//  SheetOverlayWindow.swift
//  Dropin
//
//  Created by baptiste sansierra on 12/3/26.
//

import UIKit
import SwiftUI

/// SheetOverlayWindow is used to present overlaySheet over current window
/// User interactions passes through it if not over the sheet
internal final class SheetOverlayWindow: UIWindow {
    
    @Binding private var sheetState: SheetOverlayState

    init(windowScene: UIWindowScene, sheetState: Binding<SheetOverlayState>) {
        self._sheetState = sheetState
        super.init(windowScene: windowScene)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard sheetState.availableHeights.count > 0 else {
            return nil
        }
        let hit = super.hitTest(point, with: event)
        let sheetHeight = sheetState.currentDetentHeight + sheetState.keyboardOffset
        guard self.bounds.height - point.y <= sheetHeight else {
            // Tap outside the sheet -> passes through
            return nil
        }
        // Tap inside the sheet, handle the interaction
        return hit
    }
}
