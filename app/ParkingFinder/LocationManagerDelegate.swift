//
//  LocationManagerDelegate.swift
//  ParkingFinder
//
//  Created by Rishabh Changwani on 7/1/24.
//

import Foundation

import CoreLocation
import MapKit

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            userLocation = location

            if shouldUpdateMapRegion {
                let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
                mapView.setRegion(region, animated: true)
                mapView.showsUserLocation = true
                shouldUpdateMapRegion = false
            }

            // Update distances for parking spots
            updateParkingSpotDistances()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
}
