import UIKit
import CoreLocation
import MapKit
import CoreLocationUI

struct ParkingSpot: Codable {
    let latitude: Double
    let longitude: Double
    let name: String
    let isAvailable: Bool
    var distanceFromCurrentLocation: Double? // Update to var to modify
}

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, MKLocalSearchCompleterDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationButtonPlaceholder: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    var parkingSpotDetailView: UIView!
    var parkingSpotNameLabel: UILabel!
    var parkingSpotAvailabilityLabel: UILabel!
    var parkingSpotDistanceLabel: UILabel!
    var directionsButton: UIButton!
    var closeButton: UIButton!
    var shareButton: UIButton!

    let locationManager = CLLocationManager()
    var shouldUpdateMapRegion = true
    var userLocation: CLLocation?
    var parkingSpots: [ParkingSpot] = []
    var searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()
    var selectedParkingSpot: MKAnnotation?
    var isShowingDirections = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up location manager
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        // Set up map view delegate
        mapView.delegate = self

        // Enable user interactions on the map
        mapView.isScrollEnabled = true
        mapView.isZoomEnabled = true
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = true

        // Set up search bar and search completer delegate
        searchBar.delegate = self
        searchCompleter.delegate = self

        // Set up table view delegate and data source
        tableView.delegate = self
        tableView.dataSource = self

        // Register the cell identifier
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.isHidden = true // Hide the table view initially

        // Add CLLocationButton
        setupLocationButton()

        // Add Parking Spot Detail View
        setupParkingSpotDetailView()

        // Fetch parking spots from backend
        fetchParkingSpots()
    }

    func setupLocationButton() {
        let locationButton = CLLocationButton(frame: .zero)
        locationButton.icon = .arrowFilled
        locationButton.label = .currentLocation
        locationButton.cornerRadius = 10
        locationButton.addTarget(self, action: #selector(locationButtonPressed), for: .touchUpInside)

        locationButtonPlaceholder.addSubview(locationButton)
        locationButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            locationButton.leadingAnchor.constraint(equalTo: locationButtonPlaceholder.leadingAnchor),
            locationButton.trailingAnchor.constraint(equalTo: locationButtonPlaceholder.trailingAnchor),
            locationButton.topAnchor.constraint(equalTo: locationButtonPlaceholder.topAnchor),
            locationButton.bottomAnchor.constraint(equalTo: locationButtonPlaceholder.bottomAnchor)
        ])
    }

    func setupParkingSpotDetailView() {
        parkingSpotDetailView = UIView()
        parkingSpotDetailView.backgroundColor = .white
        parkingSpotDetailView.layer.cornerRadius = 10
        parkingSpotDetailView.isHidden = true // Hide the view initially

        view.addSubview(parkingSpotDetailView)
        parkingSpotDetailView.translatesAutoresizingMaskIntoConstraints = false

        parkingSpotNameLabel = UILabel()
        parkingSpotNameLabel.font = UIFont.boldSystemFont(ofSize: 20)
        parkingSpotNameLabel.textColor = .black

        parkingSpotAvailabilityLabel = UILabel() // New availability label
        parkingSpotAvailabilityLabel.font = UIFont.systemFont(ofSize: 16)
        parkingSpotAvailabilityLabel.textColor = .gray

        parkingSpotDistanceLabel = UILabel() // New distance label
        parkingSpotDistanceLabel.font = UIFont.systemFont(ofSize: 16)
        parkingSpotDistanceLabel.textColor = .gray

        directionsButton = UIButton(type: .system)
        directionsButton.setTitle("Get Directions", for: .normal)
        directionsButton.addTarget(self, action: #selector(getDirections), for: .touchUpInside)

        closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .gray
        closeButton.addTarget(self, action: #selector(closeDetailView), for: .touchUpInside)

        shareButton = UIButton(type: .system)
        shareButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        shareButton.tintColor = .gray
        shareButton.addTarget(self, action: #selector(shareLocation), for: .touchUpInside)

        parkingSpotDetailView.addSubview(parkingSpotNameLabel)
        parkingSpotDetailView.addSubview(parkingSpotAvailabilityLabel) // Add availability label
        parkingSpotDetailView.addSubview(parkingSpotDistanceLabel) // Add distance label
        parkingSpotDetailView.addSubview(directionsButton)
        parkingSpotDetailView.addSubview(closeButton)
        parkingSpotDetailView.addSubview(shareButton)

        parkingSpotNameLabel.translatesAutoresizingMaskIntoConstraints = false
        parkingSpotAvailabilityLabel.translatesAutoresizingMaskIntoConstraints = false // Set up constraints for availability label
        parkingSpotDistanceLabel.translatesAutoresizingMaskIntoConstraints = false // Set up constraints for distance label
        directionsButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            parkingSpotDetailView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            parkingSpotDetailView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            parkingSpotDetailView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),

            parkingSpotNameLabel.topAnchor.constraint(equalTo: parkingSpotDetailView.topAnchor, constant: 10),
            parkingSpotNameLabel.leadingAnchor.constraint(equalTo: parkingSpotDetailView.leadingAnchor, constant: 10),
            parkingSpotNameLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -10),

            parkingSpotAvailabilityLabel.topAnchor.constraint(equalTo: parkingSpotNameLabel.bottomAnchor, constant: 5),
            parkingSpotAvailabilityLabel.leadingAnchor.constraint(equalTo: parkingSpotDetailView.leadingAnchor, constant: 10),
            parkingSpotAvailabilityLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -10),

            parkingSpotDistanceLabel.topAnchor.constraint(equalTo: parkingSpotAvailabilityLabel.bottomAnchor, constant: 5),
            parkingSpotDistanceLabel.leadingAnchor.constraint(equalTo: parkingSpotDetailView.leadingAnchor, constant: 10),
            parkingSpotDistanceLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -10),

            directionsButton.topAnchor.constraint(equalTo: parkingSpotDistanceLabel.bottomAnchor, constant: 10),
            directionsButton.leadingAnchor.constraint(equalTo: parkingSpotDetailView.leadingAnchor, constant: 10),
            directionsButton.bottomAnchor.constraint(equalTo: parkingSpotDetailView.bottomAnchor, constant: -10),

            closeButton.topAnchor.constraint(equalTo: parkingSpotDetailView.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: parkingSpotDetailView.trailingAnchor, constant: -10),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),

            shareButton.topAnchor.constraint(equalTo: directionsButton.topAnchor),
            shareButton.trailingAnchor.constraint(equalTo: parkingSpotDetailView.trailingAnchor, constant: -10),
            shareButton.widthAnchor.constraint(equalToConstant: 30),
            shareButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    @objc func locationButtonPressed() {
        if let location = userLocation {
            let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(region, animated: true)
        }
    }

    @objc func shareLocation() {
        guard let selectedParkingSpot = selectedParkingSpot else { return }
        let location = "\(selectedParkingSpot.coordinate.latitude), \(selectedParkingSpot.coordinate.longitude)"
        let activityController = UIActivityViewController(activityItems: [location], applicationActivities: nil)
        present(activityController, animated: true, completion: nil)
    }

    @objc func closeDetailView() {
        parkingSpotDetailView.isHidden = true
        if isShowingDirections {
            exitDirections()
        } else {
            mapView.deselectAnnotation(selectedParkingSpot, animated: true)
            selectedParkingSpot = nil
        }
    }

    @objc func getDirections() {
        guard let selectedParkingSpot = selectedParkingSpot else { return }
        showDirections(to: selectedParkingSpot)
        isShowingDirections = true
    }

    func exitDirections() {
        // Remove all route overlays from the map
        mapView.overlays.forEach { overlay in
            if overlay is MKPolyline {
                mapView.removeOverlay(overlay)
            }
        }
        isShowingDirections = false
    }

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

    func updateParkingSpotDistances() {
        guard let userLocation = userLocation else { return }

        for i in 0..<parkingSpots.count {
            let spotLocation = CLLocation(latitude: parkingSpots[i].latitude, longitude: parkingSpots[i].longitude)
            let distanceInMeters = userLocation.distance(from: spotLocation)
            let distanceInMiles = distanceInMeters / 1609.34 // Convert meters to miles
            parkingSpots[i].distanceFromCurrentLocation = distanceInMiles
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }

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

    func showParkingSpotDetail(for annotation: MKAnnotation) {
        guard let parkingSpot = parkingSpots.first(where: { $0.latitude == annotation.coordinate.latitude && $0.longitude == annotation.coordinate.longitude }) else { return }

        parkingSpotNameLabel.text = parkingSpot.name
        parkingSpotAvailabilityLabel.text = parkingSpot.isAvailable ? "Available" : "Not Available" // Set availability text
        if let distance = parkingSpot.distanceFromCurrentLocation {
            parkingSpotDistanceLabel.text = String(format: "Distance: %.2f miles", distance)
        } else {
            parkingSpotDistanceLabel.text = "Distance: N/A"
        }
        parkingSpotDetailView.isHidden = false
    }

    func fetchParkingSpots() {
        guard let activityIndicator = activityIndicator else {
            print("Activity Indicator is not set")
            return
        }

        print("Starting to fetch parking spots...")
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
        let urlString = "https://0300-216-115-73-252.ngrok-free.app/api/parkingSpots"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            showAlert(title: "Error", message: "Invalid URL")
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            return
        }

        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Failed to fetch data: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", message: "Failed to fetch data: \(error.localizedDescription)")
                    activityIndicator.stopAnimating()
                    activityIndicator.isHidden = true
                }
                return
            }

            guard let data = data else {
                print("No data returned")
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", message: "No data returned from server")
                    activityIndicator.stopAnimating()
                    activityIndicator.isHidden = true
                }
                return
            }

            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }

            do {
                let parkingSpots = try JSONDecoder().decode([ParkingSpot].self, from: data)
                self.parkingSpots = parkingSpots
                DispatchQueue.main.async {
                    print("Fetched \(parkingSpots.count) parking spots")
                    self.updateParkingSpotDistances() // Update distances after fetching
                    self.addParkingSpots(parkingSpots)
                    activityIndicator.stopAnimating()
                    activityIndicator.isHidden = true
                    print("Stopped animating activity indicator")
                }
            } catch let jsonError {
                print("Failed to decode JSON: \(jsonError)")
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", message: "Failed to decode JSON: \(jsonError)")
                    activityIndicator.stopAnimating()
                    activityIndicator.isHidden = true
                }
            }
        }.resume()
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

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

    // UITableViewDataSource methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let searchResult = searchResults[indexPath.row]
        cell.textLabel?.text = searchResult.title
        cell.detailTextLabel?.text = searchResult.subtitle
        return cell
    }

    // UITableViewDelegate methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let searchResult = searchResults[indexPath.row]
        searchBar.text = searchResult.title
        tableView.isHidden = true
        performSearch(for: searchResult)
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
