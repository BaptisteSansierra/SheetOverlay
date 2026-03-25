//
//  ContentView.swift
//  MapInspector
//
//  Created by baptiste sansierra on 12/3/26.
//

import SwiftUI
import MapKit
import SheetOverlay
import CoreLocation

@MainActor
@Observable class MapInspectorViewModel {
    var position: MapCameraPosition = .region(.barcelona)
    var showPicker: Bool = false
    var showInput: Bool = false
    var showInputAlert: Bool = false
    var lat: Double = 0
    var lon: Double = 0
    var inputLat: String = ""
    var inputLon: String = ""
    var locs: [CLLocationCoordinate2D] = []
    var detents: [SheetOverlayDetent] = [.height(250), .height(400)]
    var currentDetent = SheetOverlayDetent.height(250)
}

struct MapInspectorView: View {

    @State private var vm = MapInspectorViewModel()
    
    // MARK: - body
    var body: some View {
        VStack(spacing: 0) {
            mapView
            HStack {
                Spacer()
                Button("Pick location") {
                    vm.showPicker.toggle()
                }
                .buttonStyle(.borderedProminent)
                Spacer()
                Button("Input location") {
                    vm.inputLat = String(format: "%0.4f", vm.lat)
                    vm.inputLon = String(format: "%0.4f", vm.lon)
                    vm.showInput.toggle()
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding(.top, 30)
            .padding(.bottom, 40)
        }
        .ignoresSafeArea()
        .sheetOverlay(isPresented: $vm.showPicker, selected: $vm.currentDetent) {
            pickerView
                .sheetOverlayDetents(vm.detents)
                .sheetOverlayCornerRadius(50)
                .sheetOverlayDragIndicator(.visible)
                .sheetOverlayBackground(.ultraThinMaterial)
                .sheetOverlayShadow(color: .clear, radius: 0, x: 0, y: 0)
        }
        .sheetOverlay(isPresented: $vm.showInput) {
            inputView
                .sheetOverlayDetents([.height(200)])
                .sheetOverlayCornerRadius(50)
                .sheetOverlayBackground(.ultraThinMaterial)
                .sheetOverlayKeyboardPolicy(.maxOffset(200))
        }
    }

    // MARK: - subviews
    private var mapView: some View {
        Map(position: $vm.position) {
            ForEach(vm.locs, id: \.latitude) { l in
                Marker("\(l.latitude)-\(l.longitude)",
                       coordinate: l)
            }
        }
        .onMapCameraChange(frequency: .continuous) { ctx in
            vm.lat = ctx.region.center.latitude
            vm.lon = ctx.region.center.longitude
        }
        .overlay {
            ZStack {
                Circle()
                    .stroke(.red, lineWidth: 3)
                    .fill(.clear)
                    .frame(width: 40, height: 40)
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 37, height: 37)
                Image(systemName: "mappin.and.ellipse")
                    .font(.title3)
            }
            .opacity(vm.showPicker ? 1 : 0)
        }
    }

    private var inputView: some View {
        VStack {
            HStack {
                Text("Coordinates (keyboard offset demo)")
                    .font(.title3)
                    .fontWeight(.medium)
                    .padding(.leading)
                Spacer()
            }
            .padding(.bottom, 5)
            .padding(.top, 20)
            HStack {
                TextField("Latitude", text: $vm.inputLat)
                    .keyboardType(.numbersAndPunctuation)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .padding(.leading)
                TextField("Longitude", text: $vm.inputLon)
                    .keyboardType(.numbersAndPunctuation)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .padding(.trailing)
                Spacer()
            }
            Spacer()
            VStack(spacing: 0) {
                Spacer()
                Button("Pick location") {
                    vm.showInput.toggle()
                    vm.showInputAlert.toggle()
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 40)
            }
        }
        .alert("Not implemented",
               isPresented: $vm.showInputAlert,
               actions: {},
               message: { Text("Work in progress...") })
    }

    private var pickerView: some View {
        ZStack {
            VStack(alignment: .center, spacing: 0) {
                coordsView(title: "Coordinates DD",
                           coords: ("\(vm.lat)", "\(vm.lon)"))
                    .overlay {
                        VStack {
                            HStack {
                                Spacer()
                                expandButtonView
                            }
                            Spacer()
                        }
                    }
                
                if vm.currentDetent == vm.detents[1] {
                    coordsView(title: "Coordinates DMS",
                               coords: toDMS(CLLocationCoordinate2D(latitude: vm.lat,
                                                                    longitude: vm.lon)))

                    coordsView(title: "Coordinates DM",
                               coords: toDM(CLLocationCoordinate2D(latitude: vm.lat,
                                                                   longitude: vm.lon)))
                }
                Spacer()
            }
            .padding(.top, 30)
            VStack(spacing: 0) {
                Spacer()
                Button("Pick location") {
                    vm.showPicker.toggle()
                    pickLocation()
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func coordsView(title: String, coords: (String, String)) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.title3)
                    .fontWeight(.medium)
                    .padding(.leading)
                Spacer()
            }
            .padding(.bottom, 5)
            HStack {
                Text("Latitude: ")
                    .font(.callout)
                    .fontWeight(.medium)
                    .padding(.leading, 25)
                Text(coords.0)
                    .font(.callout)
                    .fontWeight(.light)
                Spacer()
            }
            HStack {
                Text("Longitude: ")
                    .font(.callout)
                    .fontWeight(.medium)
                    .padding(.leading, 25)
                Text(coords.1)
                    .font(.callout)
                    .fontWeight(.light)
                Spacer()
            }
            .padding(.bottom, 20)
        }
    }
    
    private var expandButtonView: some View {
        Button {
            if vm.currentDetent == vm.detents[1] {
                vm.currentDetent = vm.detents[0]
            } else {
                vm.currentDetent = vm.detents[1]
            }
        } label : {
            ZStack {
                Circle()
                    .fill(.white)
                    .shadow(radius: 4)
                    .frame(width: 35, height: 35)
                ZStack {
                    Image(systemName: "plus")
                        .opacity(vm.currentDetent == vm.detents[1] ? 0 : 1)
                    Image(systemName: "minus")
                        .opacity(vm.currentDetent == vm.detents[1] ? 1 : 0)
                }
            }
        }
        .padding(.trailing)
    }
    
    // MARK: private methods
    private func pickLocation() {
        vm.locs.append(CLLocationCoordinate2D(latitude: vm.lat,
                                              longitude: vm.lon))
    }
    
    private func toDMS(_ coordinate: CLLocationCoordinate2D) -> (String, String) {
        func convert(_ value: Double, positive: String, negative: String) -> String {
            let direction = value >= 0 ? positive : negative
            let absValue = abs(value)

            let degrees = Int(absValue)
            let minutesFull = (absValue - Double(degrees)) * 60
            let minutes = Int(minutesFull)
            let seconds = (minutesFull - Double(minutes)) * 60

            return "\(degrees)°\(minutes)'\(String(format: "%.2f", seconds))\"\(direction)"
        }

        let lat = convert(coordinate.latitude, positive: "N", negative: "S")
        let lon = convert(coordinate.longitude, positive: "E", negative: "W")

        return ("\(lat)", "\(lon)")
    }
    
    func toDM(_ coordinate: CLLocationCoordinate2D) -> (String, String) {
        func convert(_ value: Double, positive: String, negative: String) -> String {
            let direction = value >= 0 ? positive : negative
            let absValue = abs(value)

            let degrees = Int(absValue)
            let minutes = (absValue - Double(degrees)) * 60

            return "\(degrees)°\(String(format: "%.3f", minutes))'\(direction)"
        }

        let lat = convert(coordinate.latitude, positive: "N", negative: "S")
        let lon = convert(coordinate.longitude, positive: "E", negative: "W")

        return ("\(lat)", "\(lon)")
    }
}

#Preview {
    MapInspectorView()
}
