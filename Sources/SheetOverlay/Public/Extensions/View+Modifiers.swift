//
//  UIView+SheetOverlay.swift
//  Dropin
//
//  Created by baptiste sansierra on 10/3/26.
//

import SwiftUI

public extension View {
    
    func sheetOverlay<Content: View>(isPresented: Binding<Bool>,
                                     content: @escaping () -> Content) -> some View {
        modifier(SheetOverlayModifier(isPresented: isPresented,
                                      content: content))
    }
    
    func sheetOverlay<Content: View>(isPresented: Binding<Bool>,
                                     selected: Binding<SheetOverlayDetent>,
                                     content: @escaping () -> Content) -> some View {
        modifier(SheetOverlayModifier(isPresented: isPresented,
                                      selected: selected,
                                      content: content))
    }
}
