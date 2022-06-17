//
//  LocationManager.swift
//  Address Book
//
//  Created by Fawzi Rifai on 06/05/2022.
//

import MapKit
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    var manager: CLLocationManager?
    @Published var coordinateRegion: MKCoordinateRegion?
    
    var isAuthorized: Bool {
        if manager?.authorizationStatus == .authorizedWhenInUse {
            return true
        } else {
            return false
        }
    }
    
    override init() {
        super.init()
        manager = CLLocationManager()
        manager?.delegate = self
    }
    
    init(coordinateRegion: MKCoordinateRegion?) {
        super.init()
        manager = CLLocationManager()
        self.coordinateRegion = coordinateRegion
        manager?.delegate = self
    }
    
    func requestLocation() {
        if manager?.authorizationStatus == .authorizedWhenInUse {
            manager?.requestLocation()
        } else {
            manager?.requestWhenInUseAuthorization()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.first?.coordinate else { return }
        withAnimation {
            coordinateRegion?.span.latitudeDelta = 0.02
            coordinateRegion?.span.longitudeDelta = 0.02
            coordinateRegion?.center.latitude = coordinate.latitude
            coordinateRegion?.center.longitude = coordinate.longitude
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
}
