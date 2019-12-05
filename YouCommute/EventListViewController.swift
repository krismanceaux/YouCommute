//
//  SecondViewController.swift
//  YouCommute
//
//  Created by Kristopher Manceaux on 10/20/19.
//  Copyright © 2019 Kristopher Manceaux. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import SQLite
import Contacts

struct Commute{
    var eventName: String
    var source: MKMapItem?
    var destination: MKMapItem?
    var directions: MKDirections
    var arrivalTime: String
    var dateOfCommute: String
    

    
    init(source: MKPlacemark, destination: MKPlacemark, eventName: String, arrivalTime: String, dateOfCommute: String) {
        self.source = MKMapItem(placemark: source)
        self.destination = MKMapItem(placemark: destination)
        self.arrivalTime = arrivalTime
        self.dateOfCommute = dateOfCommute
        
        let request = MKDirections.Request()
        request.source = self.source
        request.destination = self.destination
        request.transportType = .automobile
        
        self.directions = MKDirections(request: request)
        self.eventName = eventName
        
    }
}

struct dbEntry{
    let id = Expression<Int>("id")
    let eventName = Expression<String>("eventName")
    let destLong = Expression<Double>("destLong")
    let destLat = Expression<Double>("destLat")
    let srcLong = Expression<Double>("srcLong")
    let srcLat = Expression<Double>("srcLat")
    let arrivalTime = Expression<String>("arrivalTime")
    let dateOfCommute = Expression<String>("dateOfCommute")
    let isSrcCurrentLoc = Expression<Bool>("isSrcCurrentLoc")
}

class EventListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let clManager = CLLocationManager()
    var currentLocation: CLLocation?

    var database: Connection!
    let commuteTable = Table("commute")

    let columns = dbEntry()
    
    var queryDate = ""
    var commutes: [Commute] = []
    var travelTimes: [Double] = []
    var selectedCommute: Commute?
    var selectedTime: Double?
    var selectedIndexPath : IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
         //self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyBest
        clManager.requestWhenInUseAuthorization()
        
        do {
            let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileUrl = documentDirectory.appendingPathComponent("users").appendingPathExtension("sqlite3")
            let database = try Connection(fileUrl.path)
            self.database = database
        } catch {
            print(error)
        }

//        do{
//            try database.run(commuteTable.drop(ifExists: true))
//        } catch {
//            print("error")
//        }

        let table = self.commuteTable.create(ifNotExists: true) {
            (table) in
            table.column(self.columns.id, primaryKey: true)
            table.column(self.columns.eventName)
            table.column(self.columns.destLat)
            table.column(self.columns.destLong)
            table.column(self.columns.srcLat)
            table.column(self.columns.srcLong)
            table.column(self.columns.arrivalTime)
            table.column(self.columns.dateOfCommute)
            table.column(self.columns.isSrcCurrentLoc)
        }

        do {
            try self.database.run(table)
        } catch {
            print(error)
        }

    }

    func getETA(direction: MKDirections, cell: UITableViewCell, indexPath:IndexPath) {
        
        direction.calculateETA { (response, error) in
            guard error == nil, let response = response else {return}
            let travelTimeLabel = cell.viewWithTag(1) as! UILabel
            let tTime = response.expectedTravelTime
            // APPEND HERE
            self.travelTimes.append(tTime)
            travelTimeLabel.text = self.formatTime(time: tTime)
        }
    }
    
    func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.medium
        formatter.timeStyle = DateFormatter.Style.none
        print(formatter.string(from: date))
        return formatter.string(from: date)
    }
    
    func formatTime(time: Double) -> String {
        // get the number of hours
        let hours = floor(time / 3600)

        var remainingSeconds = time - (3600 * hours)

        // get the number of minutes
        let minutes = floor(remainingSeconds / 60)

        remainingSeconds = remainingSeconds - (60 * minutes)
        if hours == 0{
            return ("\(Int(minutes)) min")
        }
        return ("\(Int(hours)) hr \(Int(minutes)) min")
    }

    func getPlacemark(location: CLLocation) -> MKPlacemark {
        var addressDict: [String: String] = [:]
        CLGeocoder().reverseGeocodeLocation(location){ (placemark, error) in
            if error != nil{
                print(error?.localizedDescription ?? "ERROR")
            }
            if let place = placemark?[0] {
                addressDict = [CNPostalAddressStreetKey: place.name!, CNPostalAddressCityKey: place.locality!, CNPostalAddressPostalCodeKey: place.postalCode!, CNPostalAddressISOCountryCodeKey: place.isoCountryCode!]
            }
        }
        return MKPlacemark(coordinate: location.coordinate, addressDictionary: addressDict)
    }
    
    // this function queries for all the commutes for today's date, uses the coordinates to geolocate a placemark, each placemark is put into a commute object, then the commute is appended to a list of commutes which is assigned to the commutes member variable
    func getPlacemarksFromCoordinates(){
        // list commutes
        commutes = []
        let today = queryDate == "" ? formatDate(date: Date()) : queryDate
        print("today: \(today)")
        let commutesToday = commuteTable.filter(columns.dateOfCommute == today)
        do {
            let commutesQuery = try self.database.prepare(commutesToday)
            var isEmpty = true
                   
            for commute in commutesQuery {
                print(commute)
                isEmpty = false
                var srcAddressDict: [String: String] = [:]
                var destAddressDict: [String: String] = [:]
                
            
            
                if commute[self.columns.isSrcCurrentLoc] {
                    // REQUEST THE USERS CURRENT LOCATION TO GET THE COORDINATES
                    clManager.requestLocation()
                }

                let srcLocation = commute[self.columns.isSrcCurrentLoc] && currentLocation != nil ?
                    CLLocation(latitude: currentLocation!.coordinate.latitude, longitude: currentLocation!.coordinate.longitude) :
                    CLLocation(latitude: commute[self.columns.srcLat], longitude: commute[self.columns.srcLong])
                
                
                let destLocation = CLLocation(latitude: commute[self.columns.destLat], longitude: commute[self.columns.destLong])
                
                CLGeocoder().reverseGeocodeLocation(srcLocation){ (placemark, error) in
                    if error != nil{
                        print(error?.localizedDescription ?? "ERROR")
                    }
                    if let place = placemark?[0] {
                        srcAddressDict = [CNPostalAddressStreetKey: place.name!, CNPostalAddressCityKey:
                            place.locality!, CNPostalAddressPostalCodeKey: place.postalCode!, CNPostalAddressISOCountryCodeKey: place.isoCountryCode!]

                        CLGeocoder().reverseGeocodeLocation(destLocation){ (placemark, error) in
                            if error != nil{
                                print(error?.localizedDescription ?? "ERROR")
                            }
                            if let place = placemark?[0] {
                                destAddressDict = [CNPostalAddressStreetKey: place.name!, CNPostalAddressCityKey: place.locality!, CNPostalAddressPostalCodeKey: place.postalCode!, CNPostalAddressISOCountryCodeKey: place.isoCountryCode!]
                                let srcCoordinates = commute[self.columns.isSrcCurrentLoc] && self.currentLocation != nil ?
                                    CLLocationCoordinate2DMake(self.currentLocation!.coordinate.latitude, self.currentLocation!.coordinate.longitude) :
                                    CLLocationCoordinate2DMake(commute[self.columns.srcLat], commute[self.columns.srcLong])
                                
                                
                                let destCoordinates = CLLocationCoordinate2DMake(commute[self.columns.destLat], commute[self.columns.destLong])
                                let com = Commute(source: MKPlacemark(coordinate: srcCoordinates, addressDictionary: srcAddressDict), destination: MKPlacemark(coordinate: destCoordinates, addressDictionary: destAddressDict), eventName: commute[self.columns.eventName], arrivalTime: commute[self.columns.arrivalTime], dateOfCommute: commute[self.columns.dateOfCommute])
                                // APPEND HERE
                                self.commutes.append(com)
                                self.commutes = self.commutes.sorted(by: { $0.arrivalTime < $1.arrivalTime })
                                self.tableView.reloadData()
                            }
                        }
                    }
                }
                
               
           }
            
           if isEmpty{
            alertTemplate(title: "Empty day!",msg: "There are no commutes scheduled for this day")
           }
        } catch {
           print(error)
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        //self.tableView.isUserInteractionEnabled = false
        self.travelTimes = []
        getPlacemarksFromCoordinates()
        self.tableView.reloadData()
        //self.view.isUserInteractionEnabled = false

    }
    
    
    // generic error handling alert
    func alertTemplate(title: String, msg: String){
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toEventDetails" {
            let detailsVC = segue.destination as! EventDetailsViewController
            detailsVC.commute = self.selectedCommute
            detailsVC.travelTime = self.selectedTime!
            detailsVC.indexPath = self.selectedIndexPath
        }
    }

}


extension EventListViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.selectedCommute = commutes[indexPath.row]
        self.selectedTime = travelTimes[indexPath.row]
        self.selectedIndexPath = indexPath
        performSegue(withIdentifier: "toEventDetails", sender: self)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.commutes.count
    }

    // TODO: When database is hooked up, this needs to pull commutes for today initially. And every time this view appears it needs to reload its data
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath)
        
        getETA(direction: commutes[indexPath.row].directions, cell: cell, indexPath: indexPath)
        let eventNameLabel = cell.viewWithTag(2) as! UILabel
        eventNameLabel.text = commutes[indexPath.row].eventName
//        let bg = cell.viewWithTag(4)!
//        bg.layer.cornerRadius = 26;
//        bg.layer.masksToBounds = true;
        
        
        return cell
    }
}

extension EventListViewController: CLLocationManagerDelegate{
    
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
            
        }
    }
}
