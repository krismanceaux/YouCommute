//
//  ViewController.swift
//  localSearchPractice
//
//  Created by Kristopher Manceaux on 10/22/19.
//  Copyright © 2019 Kristopher Manceaux. All rights reserved.
//

import UIKit
import MapKit

protocol HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark)
}

class FirstViewController : UIViewController{
    
    var selectedPin:MKPlacemark? = nil
    var destination: MKPlacemark? = nil
    var source: MKPlacemark? = nil
    var isSource = false
    @IBOutlet weak var fromTextField: UITextField!
    @IBOutlet weak var toTextField: UITextField!
    @IBOutlet weak var eventName: UITextField!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var timeTextField: UITextField!
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toSearchResults" {
            
            let locationSearchTable = segue.destination as! LocationSearchTableViewController
            locationSearchTable.mapView = self.mapView
            locationSearchTable.handleMapSearchDelegate = self
        }
    }
    
    @IBAction func getFromLocation(_ sender: Any) {
        self.isSource = true
        performSegue(withIdentifier: "toSearchResults", sender: self)

    }
  
    @IBAction func getToLocation(_ sender: Any) {
        self.isSource = false
        performSegue(withIdentifier: "toSearchResults", sender: self)
    }
    
    @IBAction func submitCommute(_ sender: Any) {
        //print(self.tabBarController?.viewControllers!)
        let navVC = self.tabBarController?.viewControllers![0] as! UINavigationController
        let eventListVC = navVC.viewControllers.first as! EventListViewController
        eventListVC.commutes.append(Commute(source: self.source!, destination: self.destination!, eventName: eventName.text!, arrivalTime: timeTextField.text!, dateOfCommute: dateTextField.text!))
    }
    
    @IBAction func previewRoute(_ sender: Any) {
        mapDirections()
    }
    
    
    let clManager = CLLocationManager()
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyBest
        clManager.requestWhenInUseAuthorization()
        clManager.requestLocation()
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = UIDatePicker.Mode.date
        datePicker.addTarget(self, action: #selector(dateValueChange(sender:)), for: .valueChanged)
        dateTextField.inputView = datePicker
        
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.medium
        formatter.timeStyle = DateFormatter.Style.none
        dateTextField.text = formatter.string(from: datePicker.date)
        
        
        let timePicker = UIDatePicker()
        timePicker.datePickerMode = UIDatePicker.Mode.time
        timePicker.addTarget(self, action: #selector(timeValueChange(sender:)), for: .valueChanged)
        timeTextField.inputView = timePicker
        
        formatter.dateStyle = DateFormatter.Style.none
        formatter.timeStyle = DateFormatter.Style.short
        timeTextField.text = formatter.string(from: timePicker.date)
    }
    
    @objc func timeValueChange(sender: UIDatePicker){
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.none
        formatter.timeStyle = DateFormatter.Style.short
        timeTextField.text = formatter.string(from: sender.date)
    }
    
    @objc func dateValueChange(sender: UIDatePicker){
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.medium
        formatter.timeStyle = DateFormatter.Style.none
        dateTextField.text = formatter.string(from: sender.date)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func mapDirections() {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: self.source!)
        request.destination = MKMapItem(placemark: self.destination!)
        request.requestsAlternateRoutes = false
        request.transportType = .automobile

        let directions = MKDirections(request: request)

        directions.calculate { [unowned self] response, error in
            guard let unwrappedResponse = response else { return }

            for route in unwrappedResponse.routes {
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: false)
            }
        }
    }
    
    // THROWS A BUNCH OF ERRORS IN THE CONSOLE. FIX THIS LATER
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        return renderer
    }
    
    // Outsources the directions to Apple Maps from current position
    @objc func getDirections(){
        if let selectedPin = selectedPin {
            let mapItem = MKMapItem(placemark: selectedPin)
            let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
            mapItem.openInMaps(launchOptions: launchOptions)
        }
    }
}


// CORE LOCATION MANAGER DELEGATE FUNCTIONS
// Using the core location library forces us to implement these functions
extension FirstViewController: CLLocationManagerDelegate{
    
    // Handles errors. This will throw a runtime error if it is not implmented
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error: \(error)")
    }
    
    // requests user's current location after allowing the app to use the current location
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            clManager.requestLocation()
        }
    }
    
    // updates the map to the user's location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location.coordinate, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
}


// HANDLE MAP SEARCH DELEGATE FUNCTION
extension FirstViewController: HandleMapSearch {
    
    // this function is called after a user selects from the dropdown of locations
    // when called, the selected placemark is passed to this function
    func dropPinZoomIn(placemark:MKPlacemark){
        // cache the pin
        if isSource{
            self.source = placemark
            fromTextField.text = placemark.title
        }
        else{
            self.destination = placemark
            toTextField.text = placemark.title

        }
        selectedPin = placemark
        // clear existing pins
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        if let city = placemark.locality, let state = placemark.administrativeArea {
            annotation.subtitle = "\(city), \(state)"
        }
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
}

// MAP VIEW DELEGATE FUNCTIONS
extension FirstViewController : MKMapViewDelegate {
    
    // sets the view for the when you tap on the pin on the map
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?{
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        pinView?.pinTintColor = UIColor.orange
        pinView?.canShowCallout = true
        let smallSquare = CGSize(width: 30, height: 30)
        let button = UIButton(frame: CGRect(origin: .zero, size: smallSquare))
        button.setBackgroundImage(UIImage(named: "car"), for: .normal)
        button.addTarget(self, action: #selector(getDirections), for: .touchUpInside)
        pinView?.leftCalloutAccessoryView = button
        return pinView
    }
}
