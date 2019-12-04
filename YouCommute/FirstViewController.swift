//
//  ViewController.swift
//  localSearchPractice
//
//  Created by Kristopher Manceaux on 10/22/19.
//  Copyright © 2019 Kristopher Manceaux. All rights reserved.
//

import UIKit
import MapKit
import SQLite
import CoreLocation
// ==============================================================================================================================================
import UserNotifications
import NotificationCenter
// ==============================================================================================================================================


protocol HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark)
}

class FirstViewController : UIViewController{
    
    var database: Connection!
    let commuteTable = Table("commute")
    let columns = dbEntry()
    
    var selectedPin:MKPlacemark? = nil
    var destination: MKPlacemark? = nil
    var source: MKPlacemark? = nil
    var isSource = false
    
    var currentLocation: CLLocation?
    var isSrcCurrentLoc = false
    
    let clManager = CLLocationManager()
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var fromTextField: UITextField!
    @IBOutlet weak var toTextField: UITextField!
    @IBOutlet weak var eventName: UITextField!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var timeTextField: UITextField!
    
    // ==============================================================================================================================================
    // To move the view up - Mustafa
    var isKeyboardAppear = false
    // ==============================================================================================================================================

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get user location
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyBest
        clManager.requestWhenInUseAuthorization()
        clManager.requestLocation()
        
        // format the date and time picker initial values
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
        
        // connect to database
        do {
            let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileUrl = documentDirectory.appendingPathComponent("users").appendingPathExtension("sqlite3")
            let database = try Connection(fileUrl.path)
            self.database = database
        } catch {
            print(error)
        }
        
        // ==============================================================================================================================================
        // To move the View Up when the keyboard is present in the view - Mustafa
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        // ==============================================================================================================================================

    }
    
    
    
    // ==============================================================================================================================================

    // To move the View Up when the keyboard is present in the view - Mustafa
    @objc func keyboardWillShow(notification: NSNotification) {
        if !isKeyboardAppear {
            if ((notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue) != nil {
                if self.view.frame.origin.y == 0 {
                    self.view.frame.origin.y -= 60
                }
            }
            isKeyboardAppear = true
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if isKeyboardAppear {
            if ((notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue) != nil {
                if self.view.frame.origin.y != 0{
                    self.view.frame.origin.y = 0
                }
            }
            isKeyboardAppear = false
        }
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    
    // ==============================================================================================================================================
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toSearchResults" {
            let backItem = UIBarButtonItem()
            backItem.title = "Post"
            navigationItem.backBarButtonItem = backItem
            
            let locationSearchTable = segue.destination as! LocationSearchTableViewController
            locationSearchTable.mapView = self.mapView
            locationSearchTable.handleMapSearchDelegate = self
        }
    }
    
    // segues to the table view controller that displays the search results
    @IBAction func getFromLocation(_ sender: Any) {
        self.isSource = true
        performSegue(withIdentifier: "toSearchResults", sender: self)

    }
    @IBAction func fromTextFieldDidBeginEditing(_ sender: UITextField) {
        self.isSource = true
        performSegue(withIdentifier: "toSearchResults", sender: self)
        self.fromTextField.endEditing(true)
    }
    
    // segues to the table view controller that displays the search results
    @IBAction func getToLocation(_ sender: Any) {
        self.isSource = false
        performSegue(withIdentifier: "toSearchResults", sender: self)
    }
    @IBAction func toTextFieldDidBeginEditing(_ sender: UITextField) {
        self.isSource = false
        performSegue(withIdentifier: "toSearchResults", sender: self)
        self.toTextField.endEditing(true)

    }
    
    // generic error handling alert
    func alertTemplate(msg: String){
        let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    // TODO: In the future this needs create a Commute object, and store it to the database
    @IBAction func submitCommute(_ sender: Any) {
        guard fromTextField.text!.count > 0 && toTextField.text!.count > 0 && eventName.text!.count > 0 && dateTextField.text!.count > 0 && timeTextField.text!.count > 0 else {
            
            alertTemplate(msg: "Please fill all input fields")
            return
            
        }
        
        guard self.destination != nil && self.source != nil else{
            alertTemplate(msg: "Either the destination or starting point is not a valid address. Please use the \"From\" and \"To\" buttons to lookup the address.")
            return
        }
   
        let insertCommute = self.commuteTable.insert(
            self.columns.arrivalTime <- timeTextField.text!,
            self.columns.dateOfCommute <- dateTextField.text!,
            self.columns.destLat <- (destination?.coordinate.latitude)!,
            self.columns.destLong <- (destination?.coordinate.longitude)!,
            self.columns.eventName <- (eventName.text!),
            self.columns.srcLat <- (source?.coordinate.latitude)!,
            self.columns.srcLong <- (source?.coordinate.longitude)!,
            self.columns.isSrcCurrentLoc <- (isSrcCurrentLoc))
        do {
            try self.database.run(insertCommute)
            print("INSERTED COMMUTE")
        } catch {
            print(error)
        }
        print("time text")
        print(timeTextField.text!)
        // create notification for the date that the commute is on
        let notificationManager = NotificationManager()
        // NEED TO GET THE ETA, AND THE TIME WE HAVE TO LEAVE BY FROM EVENTLISTVIEWCONTROLLER AND EVENTDETAILVIEWCONTROLLER
        
        let dateText = dateTextField.text!
        let monthText = dateText.split(separator: " ")[0]
        let dayTextWithComma = dateText.split(separator: " ")[1]
        let dayText = dayTextWithComma.split(separator: ",")[0]
        let yearText = dateText.split(separator: " ")[2]
        
        let month = getMonthNumber(month: String(monthText))
        let day = Int(dayText)
        let year = Int(yearText)
        
        let eventDetailVC = EventDetailsViewController()
        let commute = Commute(source: self.source!, destination: self.destination!, eventName: eventName.text!, arrivalTime: timeTextField.text!, dateOfCommute: dateTextField.text!)
        var commuteTime = 0.0
        commute.directions.calculateETA { (res, err) in
            guard err == nil, let res = res else {return}
            commuteTime = res.expectedTravelTime

            
            let timeToLeave = eventDetailVC.formatTime(time: commuteTime, arrivalTime: commute.arrivalTime)
            print("time to leave")
            print(timeToLeave)
            
            let timeToLeaveArr = timeToLeave.split(separator: " ")
            let timeToLeaveArr2 = timeToLeaveArr[0].split(separator: ":")
            let ttlHr = Int(timeToLeaveArr2[0])
            let ttlMin = Int(timeToLeaveArr2[1])
            
            var milHr = 0
            if timeToLeaveArr[1] == "AM"{
                milHr = ttlHr!
            } else{
                milHr = ttlHr! + 12
                if milHr == 24{
                    milHr = 0
                }
            }
            
            var dateComponents = DateComponents()
            dateComponents.year = year!
            dateComponents.month = month
            dateComponents.day = day!
            dateComponents.hour = milHr
            dateComponents.minute = ttlMin
            
            let calendar = Calendar.current
            let finalDateTime = calendar.date(from: dateComponents)
            
            
            notificationManager.sendNotification(title: commute.eventName, subTitle: "To \(commute.destination!.name ?? "your destination")", body: "It's time to leave!", badge: nil, delayUntilDateTime: dateComponents)
            
            
        }
        
        
        // Clear input fields before switching back to\
        self.isSrcCurrentLoc = false
        self.fromTextField.text = ""
        self.toTextField.text = ""
        self.eventName.text = ""
        self.source = nil
        self.destination = nil
        let overlays = self.mapView.overlays
        self.mapView.removeOverlays(overlays)
        self.clManager.requestLocation()

        self.tabBarController!.selectedIndex = 0
        
       
    }
    
    func getMonthNumber(month: String) -> Int {
        switch month {
        case "Jan":
            return 1
        case "Feb":
            return 2
        case "Mar":
            return 3
        case "Apr":
            return 4
        case "May":
            return 5
        case "Jun":
            return 6
        case "Jul":
            return 7
        case "Aug":
            return 8
        case "Sep":
            return 9
        case "Oct":
            return 10
        case "Nov":
            return 11
        case "Dec":
            return 12
        default:
            return 1
        }
    }
    
    @IBAction func previewRoute(_ sender: Any) {
        if source != nil && destination != nil{
            mapDirections()
        }
        else{
            alertTemplate(msg: "Cannot preview the route until the addresses are specified")
        }
    }
    
    // listens for the time value to change
    @objc func timeValueChange(sender: UIDatePicker){
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.none
        formatter.timeStyle = DateFormatter.Style.short
        timeTextField.text = formatter.string(from: sender.date)
    }
    
    // listens for the date value to change
    @objc func dateValueChange(sender: UIDatePicker){
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.medium
        formatter.timeStyle = DateFormatter.Style.none
        dateTextField.text = formatter.string(from: sender.date)
    }
    
    // allows you to exit editing the time, date, or text
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    // calculates the directions and creates the map overlay
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
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    // renders the map overlay
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
            self.currentLocation = location
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
            if self.currentLocation != nil{
                
                self.isSrcCurrentLoc = (placemark.coordinate.latitude == self.currentLocation!.coordinate.latitude) && (placemark.coordinate.longitude ==  self.currentLocation!.coordinate.longitude) ? true : false
        
            }
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
