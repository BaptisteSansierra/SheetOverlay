//
//  SheetOverlayState.swift
//  Dropin
//
//  Created by baptiste sansierra on 10/3/26.
//

import SwiftUI

@MainActor
@Observable internal class SheetOverlayState {
    
    // MARK: constants
    static let animationDuration: Double = 0.55
    private let defaultDetents: [SheetOverlayDetent] = [.medium]

    // MARK: configuration (comes from preferences)
    private var detents: [SheetOverlayDetent]
    private var dragIndicatorVisibility: Visibility = .automatic
    private(set) var cornerRadius: CGFloat = 20
    private(set) var background: AnyShapeStyle = AnyShapeStyle(.thinMaterial)
    private(set) var shadow: SheetOverlayShadowConfig = .default
    private(set) var keyboardPolicy: SheetOverlayKeyboardPolicy = .ignore

    // MARK: computed from detents
    private var detentHeights: [CGFloat] = []
    private(set) var detentMap: [CGFloat: SheetOverlayDetent] = [:]
    private(set) var availableHeights: [CGFloat] = []

    // MARK: detents
    private(set) var defaultDetentIndex: Int = 0
    private(set) var currentDetentIndex: Int = 0

    // MARK: public properties
    private(set) var keyboardPresented: Bool = false
    private var keyboardHeight: CGFloat = 0
    private(set) var keyboardOffset: CGFloat = 0

    // MARK: computed properties
    var isPresented: Bool = false {
        didSet {
            // Reset detent index when hidden
            if !isPresented {
                currentDetentIndex = defaultDetentIndex
            }
        }
    }
    var dragIndicatorVisible: Bool {
        switch dragIndicatorVisibility {
            case .automatic:
                availableHeights.count > 1
            case .hidden:
                false
            case .visible:
                true
        }
    }
    var defaultDetentHeight: CGFloat {
        guard availableHeights.count > 0 else {
            assertionFailure("empty detents")
            return 0
        }
        guard defaultDetentIndex < availableHeights.count else {
            assertionFailure("out of bounds")
            return 0
        }
        return CGFloat(availableHeights[defaultDetentIndex])
    }
    var currentDetentHeight: CGFloat {
        guard availableHeights.count > 0 else {
            assertionFailure("empty detents")
            return 0
        }
        guard currentDetentIndex < availableHeights.count else {
            assertionFailure("out of bounds")
            return 0
        }
        return availableHeights[currentDetentIndex]
    }
    var firstDetentHeight: CGFloat {
        guard availableHeights.count > 0 else {
            assertionFailure("empty detents")
            return 0
        }
        return CGFloat(availableHeights[0])
    }
    var lastDetentHeight: CGFloat {
        guard availableHeights.count > 0 else {
            assertionFailure("empty detents")
            return 0
        }
        return CGFloat(availableHeights[availableHeights.count - 1])
    }
    
    var currentDetent: SheetOverlayDetent? {
        detent(at: currentDetentIndex)
    }
    
    // MARK: inits
    init(isPresented: Bool) {
        self.isPresented = isPresented
        self.detents = defaultDetents
        computeDetents()
        configureNotifications()
    }

    init(isPresented: Bool, detents: [SheetOverlayDetent]) {
        self.isPresented = isPresented
        self.detents = detents
        computeDetents()
        configureNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: public methods
    func detent(at index: Int) -> SheetOverlayDetent? {
        guard index >= 0 else {
            assertionFailure("wrong index \(index)")
            return nil
        }
        guard index < availableHeights.count else {
            assertionFailure("index \(index) out of bounds")
            return nil
        }
        let height = availableHeights[index]
        guard let detent = detentMap[height] else {
            assertionFailure("Couldn't retrieve detent from height \(height)")
            return nil
        }
        return detent
    }

    func updateDetents(detents: [SheetOverlayDetent]) {
        guard detents.count > 0 else {
            self.detents = defaultDetents
            computeDetents()
            return
        }
        self.detents = detents
        computeDetents()
    }
    
    func setDragIndicator(_ v: Visibility) {
        dragIndicatorVisibility = v
    }

    func setCornerRadius(_ v: CGFloat) {
        cornerRadius = v
    }

    func setBackground(_ v: AnyShapeStyle) {
        background = v
    }

    func setShadow(_ v: SheetOverlayShadowConfig) {
        shadow = v
    }

    func setKeyboardPolicy(_ v: SheetOverlayKeyboardPolicy) {
        keyboardPolicy = v
    }

    func setDefaultDetent(index: Int) {
        guard index >= 0 else {
            assertionFailure("index(\(index)) out of bounds (\(availableHeights.count))")
            defaultDetentIndex = 0
            return
        }
        guard index < availableHeights.count else {
            assertionFailure("index(\(index)) out of bounds (\(availableHeights.count))")
            defaultDetentIndex = 0
            return
        }
        // Set current also when set default
        defaultDetentIndex = index
        currentDetentIndex = index
    }

    func updateCurrentDetent(index: Int) {
        guard index >= 0 else {
            assertionFailure("index(\(index)) out of bounds (\(availableHeights.count))")
            currentDetentIndex = defaultDetentIndex
            return
        }
        guard index < availableHeights.count else {
            assertionFailure("index(\(index)) out of bounds (\(availableHeights.count))")
            currentDetentIndex = defaultDetentIndex
            return
        }
        currentDetentIndex = index
    }

    func setDefaultDetent(detent: SheetOverlayDetent) {
        guard let idx = detentIndex(detent) else { return }
        setDefaultDetent(index: idx)
    }

    func updateCurrentDetent(detent: SheetOverlayDetent) {
        guard let idx = detentIndex(detent) else { return }
        updateCurrentDetent(index: idx)
    }

    func dismiss() {
        isPresented = false
        currentDetentIndex = defaultDetentIndex
    }
    
    func getClosestDetentIndex(currentHeight: CGFloat) -> Int? {
        guard availableHeights.count > 0 else {
            return nil
        }
        var heightDeltas: [CGFloat] = []
        for idx in availableHeights.indices {
            heightDeltas.append(abs(CGFloat(availableHeights[idx]) - currentHeight))
        }
        guard let min = heightDeltas.min() else {
            assertionFailure("no min")
            return nil
        }
        guard let minIndex = heightDeltas.firstIndex(of: min) else {
            assertionFailure("not found")
            return nil
        }
        return minIndex
    }

    // MARK: private methods
    private func configureNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        keyboardPresented = true
        keyboardHeight = frame.height
        guard keyboardPolicy != .ignore else { return }
        withAnimation(.spring(response: duration, dampingFraction: 1.0, blendDuration: 0).delay(0.3)) {
            switch keyboardPolicy {
                case .ignore:
                    keyboardOffset = 0
                case .fullOffset:
                    keyboardOffset = keyboardHeight
                case .maxOffset(let maxHeight):
                    keyboardOffset = min(maxHeight, keyboardHeight)
            }
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        keyboardPresented = false
        keyboardHeight = 0
        withAnimation(.spring(response: duration, dampingFraction: 1.0, blendDuration: 0)) {
            keyboardOffset = 0
        }
    }
    
    private func detentIndex(_ detent: SheetOverlayDetent) -> Int? {
        guard let idx = detentMap.firstIndex(where: { $0.value == detent }) else {
            assertionFailure("Unknown detent \(detent), detens=\(detents)  -  detentHeights=\(detentHeights)")
            return nil
        }
        let height = detentMap[idx].key
        guard let heightIdx = availableHeights.firstIndex(where: { height == $0 }) else {
            assertionFailure("height \(height) not found")
            return nil
        }
        return heightIdx
    }
    
    private func computeDetents() {

        // Limit the heights to safe area + some margin
        let maxHeight: CGFloat = UIScreen.main.bounds.height - UIApplication.rootTopSafeArea() - 40
        let minHeight: CGFloat = UIApplication.rootBottomSafeArea() + 40

        var map: [CGFloat: SheetOverlayDetent] = [:]

        var heights = detents.map { detent -> CGFloat in
            switch detent {
                case .height(let h):
                    let height = h.clamp(min: minHeight, max: maxHeight)
                    map[height] = detent
                    return height
                //case .inherited:
                //    return sheetState.contentHeight.clamp(min: 15, max: maxHeight)
                case .large:
                    let height = maxHeight
                    map[height] = detent
                    return height
                case .medium:
                    let height = maxHeight * 0.5
                    map[height] = detent
                    return height
                case .fraction(let f):
                    let clamped = f.clamp(min: 0, max: 1)
                    let height = (clamped * maxHeight).clamp(min: minHeight, max: maxHeight)
                    map[height] = detent
                    return height
                }
        }
        detentHeights = heights
        detentMap = map

        // Sort
        heights.sort()
        // Remove duplicates
        var deduped: [CGFloat] = []
        for h in heights {
            if deduped.last != h { deduped.append(h) }
        }
        availableHeights = deduped
    }
}
