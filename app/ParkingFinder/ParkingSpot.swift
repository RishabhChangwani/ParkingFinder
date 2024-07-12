//
//  ParkingSpot.swift
//  ParkingFinder
//
//  Created by Rishabh Changwani on 7/1/24.
//

import Foundation

struct ParkingSpot: Codable {
    let latitude: Double
    let longitude: Double
    let name: String
    let isAvailable: Bool
    var distanceFromCurrentLocation: Double? // Update to var to modify
}
