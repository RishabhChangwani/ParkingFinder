//
//  SearchBarDelegate.swift
//  ParkingFinder
//
//  Created by Rishabh Changwani on 7/1/24.
//

import Foundation
import UIKit
import MapKit

extension ViewController: UISearchBarDelegate, MKLocalSearchCompleterDelegate {
    // UISearchBarDelegate methods
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            tableView.isHidden = true
            addParkingSpots(parkingSpots)
        } else {
            tableView.isHidden = false
            searchCompleter.queryFragment = searchText
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        tableView.isHidden = true
    }

    // MKLocalSearchCompleterDelegate methods
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        tableView.reloadData()
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Error finding completion: \(error.localizedDescription)")
    }

    func performSearch(for completion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        search.start { [weak self] (response, error) in
            guard let self = self else { return }

            if let error = error {
                print("Error performing search: \(error.localizedDescription)")
                self.showAlert(title: "Error", message: "Search failed: \(error.localizedDescription)")
                return
            }

            guard let response = response, let item = response.mapItems.first else {
                print("No search results found")
                self.showAlert(title: "Error", message: "No search results found")
                return
            }

            let coordinate = item.placemark.coordinate
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            self.mapView.setRegion(region, animated: true)

            let filteredSpots = self.parkingSpots.filter { spot in
                let spotLocation = CLLocation(latitude: spot.latitude, longitude: spot.longitude)
                return spotLocation.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) <= 1000
            }

            self.addParkingSpots(filteredSpots)
        }
    }
}
