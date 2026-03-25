//
//  SheetOverlayView.swift
//  Dropin
//
//  Created by baptiste sansierra on 10/3/26.
//

import SwiftUI

/// SheetOverlayView mimics Apple sheet view
/// Sheet can be dragged from a detent to another
/// Clipping issues are avoided by having always height >=<min detent height>, passed this point the sheet is offseted
internal struct SheetOverlayView<Content: View>: View {
    
    // MARK: States & Bindings
    @Binding private var sheetState: SheetOverlayState
    @GestureState private var dragGestureOffset: CGFloat = 0
    @State private var currentHeight: CGFloat = 0
    @State private var currentOffset: CGFloat = 0
    @State private var dragging: Bool = false
    @State private var dragOffset: CGFloat = 0

    // MARK: private properties
    private let content: () -> Content
    #if DEBUG
    private let debug_displayDetents: Bool = false
    private let debug_displaySheetBorder: Bool = false
    #endif
    
    // MARK: init
    init(sheetState: Binding<SheetOverlayState>,
         @ViewBuilder content: @escaping () -> Content) {
        self._sheetState = sheetState
        self.content = content
    }
    
    // MARK: body
    var body: some View {
        ZStack {
            Color.clear
                .ignoresSafeArea()
            
            if sheetState.availableHeights.count != 0 {
                sheetView
            } else {
                ContentUnavailableView("Damned !",
                                       systemImage: "multiply")
            }

            #if DEBUG
            if debug_displayDetents {
                ForEach(sheetState.availableHeights.indices, id: \.self) { idx in
                    ZStack {
                        VStack(spacing: 0){
                            Spacer()
                            Text(verbatim: "Detent: \(sheetState.detentMap[sheetState.availableHeights[idx]]!)")
                                .padding(.horizontal, 5)
                                .padding(.vertical, 10)
                                .background {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.white)
                                        .opacity(0.45)
                                }
                            Rectangle()
                                .frame(height: 1)
                                .padding(.bottom, sheetState.availableHeights[idx])
                        }
                    }
                    .ignoresSafeArea()
                }
            }
            #endif
        }
        .onAppear {
            guard sheetState.availableHeights.count > 0 else {
                return
            }
            updatePosition(presented: sheetState.isPresented,
                           detentHeight: sheetState.defaultDetentHeight,
                           animate: false)
        }
        .onChange(of: sheetState.isPresented) { _, newValue in
            guard sheetState.availableHeights.count > 0 else {
                return
            }
            updatePosition(presented: newValue,
                           detentHeight: sheetState.defaultDetentHeight,
                           animate: true)
        }
        .onChange(of: sheetState.currentDetentIndex) { _, newValue in
            guard sheetState.availableHeights.count > 0 else {
                return
            }
            guard sheetState.isPresented else {
                // Not relevant anymore
                return
            }
            updatePosition(presented: sheetState.isPresented,
                           detentHeight: sheetState.availableHeights[newValue],
                           animate: true)
        }
    }
    
    @ViewBuilder
    private var sheetView: some View {
        VStack {
            Spacer()
            
            ZStack(alignment: .center) {
                // Background
                UnevenRoundedRectangle(topLeadingRadius: sheetState.cornerRadius,
                                       topTrailingRadius: sheetState.cornerRadius)
                    .fill(sheetState.background)
                    .shadow(color: sheetState.shadow.color,
                            radius: sheetState.shadow.radius,
                            x: sheetState.shadow.offset.width,
                            y: sheetState.shadow.offset.height)
                
                // Drag indicator
                if sheetState.dragIndicatorVisible {
                    VStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.gray)
                            .frame(width: 33, height: 4)
                            .padding(.top, 4)
                        Spacer()
                    }
                }
                
                // Sheet content
                ZStack(alignment: .center) {
                    self.content()
                }
                .frame(height: currentHeight)
                .clipShape(Rectangle())
            }
            .frame(height: currentHeight)
            .offset(x: 0, y: currentOffset - sheetState.keyboardOffset)
            #if DEBUG
            .border(debug_displaySheetBorder ? .blue : .clear, width: 3)
            #endif
        }
        .ignoresSafeArea()
        .simultaneousGesture(
            DragGesture(minimumDistance: 10)
                .updating($dragGestureOffset) { value, state, _ in
                    guard sheetState.keyboardOffset == 0 else {
                        // Disable dragging if
                        return
                    }
                    if !dragging {
                        // Set dragging mode
                        dragging = true
                    }
                    state = value.translation.height
                    updateDrag(value)
                }
                .onEnded { value in
                    guard sheetState.keyboardOffset == 0 else { return }
                    dragging = false
                    finalizeDrag(currentHeight: currentHeight,
                                 dragVelocity: value.velocity.height)
                }
        )
    }
    
    // MARK: private methods
    private func updatePosition(presented: Bool,
                                detentHeight: CGFloat,
                                animate: Bool) {
        //print("===================")
        //print("updatePosition(presented: \(presented), detentHeight: \(detentHeight), animate: \(animate))")
        //print("  currentHeight: \(currentHeight)")
        //print("  currentOffset: \(currentOffset)")
        if dragging {
            assertionFailure("This methos is not supposed to be used during dragging")
        }
        let duration: Double = animate ? SheetOverlayState.animationDuration : 0
        var height = detentHeight
        var offset = detentHeight
        guard presented else {
            //print("  SET currentHeight: \(height)")
            //print("  SET currentOffset: \(offset)")
            withAnimation(.spring(response: duration, dampingFraction: 1, blendDuration: 0)) {
                currentHeight = height
                currentOffset = offset
            }
            //print("updatePosition => height:\(currentHeight) offset:\(currentOffset)")
            return
        }
        height = detentHeight
        offset = 0
        //print("  SET currentHeight: \(height)")
        //print("  SET currentOffset: \(offset)")
        withAnimation(.spring(response: duration, dampingFraction: 1, blendDuration: 0)) {
            currentHeight = height
            currentOffset = offset
        }
    }

    private func updateDrag(_ value: DragGesture.Value) {
        let idx = sheetState.currentDetentIndex
        let currentDetentHeight = sheetState.availableHeights[idx]

        // Compute drag offset
        dragOffset = value.translation.height
        if currentDetentHeight - dragOffset > sheetState.lastDetentHeight {
            // High limit reached, limit the dragging
            let delta = currentDetentHeight - sheetState.lastDetentHeight
            let overflow = dragOffset - delta
            dragOffset = delta + -(pow(log(abs(overflow)), 2))
        }

        // Compute height and offset
        let minHeight = sheetState.firstDetentHeight
        if currentHeight == minHeight && dragOffset > 0 {
            // Dragging below minimum, use offset instead of height
            if currentDetentHeight == 0 {
                currentOffset = dragOffset
            } else {
                currentOffset = dragOffset - (currentDetentHeight - minHeight)
            }
            if currentOffset < 0 {
                // If we're offseting above minimum, cancel offset and adjust height
                currentHeight += -1 * currentOffset
                currentOffset = 0
            }
        } else {
            // Dragging above minimum, update height
            currentHeight = currentDetentHeight - dragOffset
            currentOffset = 0
            
            if currentHeight < minHeight {
                // If the drag moved sheet below minimum, set height limit and adjust offset
                currentOffset = minHeight - currentHeight
                currentHeight = minHeight
            }
        }
    }
    
    private func finalizeDrag(currentHeight: CGFloat, dragVelocity: CGFloat) {
        defer {
            dragOffset = 0
        }
        guard let closestDetentIndex = sheetState.getClosestDetentIndex(currentHeight: currentHeight) else {
            // Should never happen
            assertionFailure("getClosestDetentIndex gives nil from height \(currentHeight)")
            dismiss()
            return
        }
        var nextDetentIndex: Int
        // Detect swipe (aka fast drag), discard unintentional (undersized) swipes as
        if dragVelocity > 200 && abs(dragOffset) > 10 {
            // Set lower detent
            nextDetentIndex = closestDetentIndex - 1
            guard nextDetentIndex != -1 else {
                print("Velocity: \(dragVelocity) => dismiss")
                dismiss()
                return
            }
        } else if dragVelocity < -200 && abs(dragOffset) > 10 {
            // Set higher detent
            if closestDetentIndex == sheetState.availableHeights.count - 1 {
                nextDetentIndex = closestDetentIndex
            } else {
                nextDetentIndex = closestDetentIndex + 1
            }
        } else {
            guard currentHeight > sheetState.firstDetentHeight * 0.5 &&
            currentOffset < sheetState.firstDetentHeight * 0.5 else {
                //print("  => drag released on dismiss zone ==> dismiss")
                dismiss()
                return
            }
            nextDetentIndex = closestDetentIndex
        }
        if nextDetentIndex != sheetState.currentDetentIndex {
            // We reached a different detent, update it
            sheetState.updateCurrentDetent(index: nextDetentIndex)
        } else {
            // Same detent as before dragging, go back to detent height
            updatePosition(presented: true,
                           detentHeight: sheetState.currentDetentHeight,
                           animate: true)
        }
    }
    
    private func dismiss() {
        // Hide the sheet
        sheetState.dismiss()
    }
}

#if DEBUG

struct MockSheeetOverlayView: View {
    
    @State var sheetOverlayState: SheetOverlayState
    @State var appleSheet = false
    @State var sliderValue: Double = 2

    var appleDetents: Set<PresentationDetent> {
        [.height(300)]
//        Set(sheetOverlayState.detentHeights.map({ PresentationDetent.height($0) }))
    }

    init() {
        let state = SheetOverlayState(isPresented: false,
                                      detents: [.height(15),
                                                .height(400),
                                                .height(600)])
        _sheetOverlayState = State(initialValue: state)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Button("Toggle Apple Sheet") {
                        appleSheet.toggle()
                    }
                    .padding()
                    .buttonStyle(.borderedProminent)
                    Spacer()
                    Button("Toggle SheetOverlay") {
                        sheetOverlayState.isPresented.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
                Slider(value: $sliderValue, in: 0...10)
                    .padding()
                    .padding(.top, 40)
                
                Spacer()
                
            }
            
            SheetOverlayView(sheetState: $sheetOverlayState,
                             content: sheetContent)
        }
        .sheet(isPresented: $appleSheet) {
            sheetContent()
                .presentationDetents(appleDetents)
                .presentationDragIndicator(.automatic)
                .presentationCornerRadius(100)
                .presentationBackground(.purple)
                .presentationBackgroundInteraction(
                    .enabled(upThrough: .large)
                )
        }
    }
    
    func sheetContent() -> some View {
        VStack {
            Button("qqq", action: {})
                .buttonStyle(.borderedProminent)
                .padding()
            Button("aaa", action: {})
                .buttonStyle(.borderedProminent)
                .padding()
            Button("zzz", action: {})
                .buttonStyle(.borderedProminent)
                .padding()
        }
    }
}

#Preview {
    MockSheeetOverlayView()
}

#endif

