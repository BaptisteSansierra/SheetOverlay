//
//  File.swift
//  MapInspector
//
//  Created by baptiste sansierra on 12/3/26.
//


import CoreLocation

extension CLLocationCoordinate2D {
    static var london: CLLocationCoordinate2D {
        .init(latitude: 51.509865, longitude: -0.118092)
    }
    static var barcelona: CLLocationCoordinate2D {
        .init(latitude: 41.390205, longitude: 2.154007)
    }
    
    static var paris: CLLocationCoordinate2D {
        .init(latitude: 48.864716, longitude: 2.349014)
    }
}
