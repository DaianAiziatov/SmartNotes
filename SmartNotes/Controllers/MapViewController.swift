//
//  MapViewController.swift
//  SmartNotes
//
//  Created by Daian Aiziatov on 14/03/2019.
//  Copyright © 2019 Daian Aiziatov. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

protocol MapViewControllerDelegate {
    func saveCoordinates(coordinates: CLLocationCoordinate2D)
}

class MapViewController: UIViewController, AlertDisplayable {

    var delegate: MapViewControllerDelegate?
    var location: CLLocationCoordinate2D?

    private var locationManager = CLLocationManager()
    private var annotation = MKPointAnnotation()

    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var currentLocationButton: UIButton! {
        didSet {
            currentLocationButton.layer.masksToBounds = true
            currentLocationButton.clipsToBounds = true
            currentLocationButton.layer.cornerRadius = currentLocationButton.frame.height/2
        }
    }

    @IBAction func changeMapType(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 1: mapView.mapType = .satellite
        default: mapView.mapType = .standard
        }
    }
    
    @IBAction func currentLocationTapped(_ sender: UIButton) {
        mapView.showsUserLocation = true
        if CLLocationManager.locationServicesEnabled() == true {
            if CLLocationManager.authorizationStatus() == .restricted ||
                CLLocationManager.authorizationStatus() == .denied ||
                CLLocationManager.authorizationStatus() == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
            }
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.delegate = self
            locationManager.startUpdatingLocation()
        } else {
            displayAlert(with: "Please turn on location services or GPS", message: "You can do it in preferences manually")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        annotation.coordinate = mapView.centerCoordinate
        if let location = location {
            annotation.coordinate = location
            let region = MKCoordinateRegion(center: location, span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002))
            mapView.setRegion(region, animated: true)
        }
        mapView.addAnnotation(annotation)
        self.navigationItem.largeTitleDisplayMode = .never
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveLocation))
    }

    

    @objc
    private func saveLocation() {
        if let location = location {
            delegate?.saveCoordinates(coordinates: location)
            self.navigationController?.popViewController(animated: true)
        }
    }

}

extension MapViewController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002))
        mapView.setRegion(region, animated: true)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        displayAlert(with: "Oops!:(", message: "Unable to access your current location. Try again later.")
        print("[MapViewController] \(#function) Error: \(error.localizedDescription)")
    }
}

extension MapViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        location = mapView.centerCoordinate
        annotation.coordinate = mapView.centerCoordinate
    }
}
