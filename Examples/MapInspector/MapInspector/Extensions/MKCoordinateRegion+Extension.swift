//
//  MKCoordinateRegion+Extension.swift
//  MapInspector
//
//  Created by baptiste sansierra on 12/3/26.
//

import MapKit

public extension MKCoordinateRegion {
        
    static var barcelona: MKCoordinateRegion {
        .init(
            center: CLLocationCoordinate2D.barcelona,
            span: .init(latitudeDelta: 0.3, longitudeDelta: 0.3)
        )
    }
}
