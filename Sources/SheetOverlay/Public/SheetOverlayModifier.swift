//
//  SheetOverlayModifier.swift
//  Dropin
//
//  Created by baptiste sansierra on 10/3/26.
//

import SwiftUI
import UIKit

public struct SheetOverlayModifier<T: View>: ViewModifier {

    // MARK: States & Bindings
    private var selectedDetent: Binding<SheetOverlayDetent>?
    @Binding private var isPresented: Bool
    // Shared state (bridged into UIWindow)
    @State private var sheetState: SheetOverlayState
    // Window
    @State private var overlayWindow: SheetOverlayWindow?
    // Hosting reference
    @State private var hostingController: UIHostingController<AnyView>?

    // MARK: private properties
    private var sheetContent: () -> T
 
    // MARK: init
    internal init(isPresented: Binding<Bool>,
                  selected: Binding<SheetOverlayDetent>? = nil,
         @ViewBuilder content: @escaping () -> T) {
        self._isPresented = isPresented
        self.sheetContent = content
        self.selectedDetent = selected

        // Create state
        let state = SheetOverlayState(isPresented: isPresented.wrappedValue)
        _sheetState = State(initialValue: state)
    }

    
    // MARK: body
    public func body(content: Content) -> some View {
        content
            .onDisappear {
                teardownOverlayWindow()
            }
            .onAppear {
                setupOverlayWindow()
            }
            .background {

                ZStack {
                    // invisible — purpose is to catch re-renders
                    _HostingControllerUpdater(
                        hostingController: hostingController,
                        view: SheetOverlayView(sheetState: $sheetState,
                                               // fresh closure every render)
                                               content: sheetContent))
                        .frame(width: 0, height: 0)

                    // invisible — purpose is to catch changes
                    self.sheetContent()
                        .frame(width: 0, height: 0)
                        .hidden()
                        .onPreferenceChange(SheetOverlayDetentsPreferenceKey.self) {
                            guard !$0.isEmpty else { return }
                            sheetState.updateDetents(detents: $0)
                            // When setting the detents, if there's a selected one, select it
                            if let selectedDetent = selectedDetent {
                                sheetState.setDefaultDetent(detent: selectedDetent.wrappedValue)
                            }
                        }
                        .onPreferenceChange(SheetOverlayDragIndicatorPreferenceKey.self) {
                            sheetState.setDragIndicator($0)
                        }
                        .onPreferenceChange(SheetOverlayCornerRadiusPreferenceKey.self) {
                            sheetState.setCornerRadius($0)
                        }
                        .onPreferenceChange(SheetOverlayBackgroundPreferenceKey.self) {
                            sheetState.setBackground($0.style)
                        }
                        .onPreferenceChange(SheetOverlayShadowPreferenceKey.self) {
                            sheetState.setShadow($0)
                        }
                        .onPreferenceChange(SheetOverlayKeyboardPolicyPreferenceKey.self) {
                            sheetState.setKeyboardPolicy($0)
                        }
                        // Caller → sheet: push external changes in
                        .onChange(of: selectedDetent?.wrappedValue) { _, newValue in
                            guard let newValue else { return }
                            guard newValue != sheetState.currentDetent else { return }  // break feedback loop
                            sheetState.updateCurrentDetent(detent: newValue)
                        }
                        // Sheet → caller: push internal changes out
                        .onChange(of: sheetState.currentDetentIndex) { _, newValue in
                            guard let newDetent = sheetState.detent(at: newValue) else { return }
                            guard selectedDetent?.wrappedValue != newDetent else { return }  // break feedback loop
                            selectedDetent?.wrappedValue = newDetent
                        }
                }
            }
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    // Show window and launch animation after a quick delay
                    showOverlayWindow()
                    Task {
                        try? await Task.sleep(for: .seconds(0.1))
                        sheetState.isPresented = newValue
                    }
                }
                else {
                    sheetState.isPresented = newValue
                    // Hide the window after dismiss animation completes
                    Task {
                        try? await Task.sleep(for: .seconds(SheetOverlayState.animationDuration + 0.1))
                        hideOverlayWindow()
                    }
                }
            }
            .onChange(of: sheetState.isPresented) { _, newValue in
                isPresented = newValue
            }
    }

    // MARK: - Window stuff
    private func setupOverlayWindow() {
        guard overlayWindow == nil else { return }
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        let window = SheetOverlayWindow(windowScene: scene,
                                        sheetState: $sheetState)
        window.backgroundColor = .clear
        window.windowLevel = .normal + 1
        window.isHidden = true
        overlayWindow = window
        let sheetOverlayView = SheetOverlayView(sheetState: $sheetState,
                                            content: sheetContent)
        hostingController = UIHostingController(rootView: AnyView(sheetOverlayView))
        hostingController!.view.backgroundColor = .clear
        // handle keyboard avoidance
        hostingController!.safeAreaRegions = .all
        window.rootViewController = hostingController!
    }
    
    private func showOverlayWindow() {
        overlayWindow?.isHidden = false
        overlayWindow?.makeKeyAndVisible()
    }

    private func hideOverlayWindow() {
        isPresented = false
        overlayWindow?.isHidden = true
        overlayWindow?.resignKey()
    }

    private func teardownOverlayWindow() {
        overlayWindow?.isHidden = true
        overlayWindow?.rootViewController = nil
        overlayWindow = nil
    }
}

#if DEBUG

struct MockSheetOverlayView: View {

    @State var isSheetOverlayPresented: Bool = false
    @State var color: Color = .green

    var body: some View {
        NavigationStack {
            ZStack {
                color
                VStack {
                    Button("Toggle SheetOverlay") {
                        isSheetOverlayPresented.toggle()
                    }
                    .padding()
                }
            }
            .navigationTitle("demo")
            .sheetOverlay(isPresented: $isSheetOverlayPresented) {
                sheetContent
                    .sheetOverlayDetents([.height(250), .medium, .large])
            }
        }
    }

    var sheetContent: some View {
        VStack {
            Button("BROWN") {
                color = .brown
            }
            .buttonStyle(.borderedProminent)
            Button("PURPLE") {
                color = .purple
            }
            .buttonStyle(.borderedProminent)
            Button("PINK") {
                color = .pink
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    MockSheetOverlayView()
}

#endif



private struct _HostingControllerUpdater<T: View>: UIViewRepresentable {
    var hostingController: UIHostingController<AnyView>?
    var view: T

    func makeUIView(context: Context) -> UIView { UIView() }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Called every SwiftUI render cycle automatically
        hostingController?.rootView = AnyView(view)
    }
}
