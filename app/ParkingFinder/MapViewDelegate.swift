//
//  MapViewDelegate.swift
//  ParkingFinder
//
//  Created by Rishabh Changwani on 7/1/24.
//

import Foundation

import MapKit

extension ViewController: MKMapViewDelegate {
    func addParkingSpots(_ parkingSpots: [ParkingSpot]) {
        for spot in parkingSpots {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude)
            annotation.title = spot.name
            annotation.subtitle = spot.isAvailable ? "Available" : "Not Available"
            mapView.addAnnotation(annotation)
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }

        let identifier = "ParkingSpot"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = false

            annotationView?.glyphImage = UIImage(named: "parking_icon")
            
            annotationView?.markerTintColor = (annotation.subtitle == "Available") ? .green : .red
        } else {
            annotationView?.annotation = annotation
        }

        return annotationView
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else { return }

        selectedParkingSpot = annotation
        showParkingSpotDetail(for: annotation)
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        parkingSpotDetailView.isHidden = true
        selectedParkingSpot = nil
        exitDirections()
    }

    func showDirections(to destination: MKAnnotation) {
        guard let userLocation = userLocation else {
            showAlert(title: "Error", message: "User location not available")
            return
        }

        let sourcePlacemark = MKPlacemark(coordinate: userLocation.coordinate)
        let destinationPlacemark = MKPlacemark(coordinate: destination.coordinate)

        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem(placemark: sourcePlacemark)
        directionRequest.destination = MKMapItem(placemark: destinationPlacemark)
        directionRequest.transportType = .automobile

        let directions = MKDirections(request: directionRequest)
        directions.calculate { [weak self] (response, error) in
            guard let self = self else { return }

            if let error = error {
                print("Error calculating directions: \(error.localizedDescription)")
                self.showAlert(title: "Error", message: "Error calculating directions: \(error.localizedDescription)")
                return
            }

            guard let response = response, let route = response.routes.first else {
                self.showAlert(title: "Error", message: "No route found")
                return
            }

            self.mapView.addOverlay(route.polyline, level: .aboveRoads)
            let rect = route.polyline.boundingMapRect
            self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = .blue
            polylineRenderer.lineWidth = 5.0
            return polylineRenderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}
