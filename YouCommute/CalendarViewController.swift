//
//  ViewController.swift
//  Calander Test 2
//
//  Created by Pranav Saineni on 11/5/19.
//  Copyright © 2019 Pranav Saineni. All rights reserved.
//

import UIKit
import FSCalendar
import SQLite
import EventKit
import MapKit
import CoreLocation
import Contacts


class CalendarViewController: UIViewController {
    var currentLocation: CLLocation?
    let clManager = CLLocationManager()
    let col = dbEntry()
    let commuteTable = Table("commute")

    var source: MKPlacemark? = nil

    @IBOutlet weak var inti: UIButton!
    @IBOutlet weak var calendar_view: FSCalendar!
    
    @IBAction func integrate(_ sender: UIButton) {
        let eventStore = EKEventStore()
        
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            readEvents()
            addDb()
        case .denied:
            print("Access denied")
        case .notDetermined:
            
            eventStore.requestAccess(to: .event, completion: { (granted: Bool, NSError) -> Void in
                if granted {
                    self.readEvents()
                    
                }else{
                    print("Access denied")
                }
            })
        default:
            print("Case Default")
        }
        inti.isEnabled = false
        inti.alpha = 0.0
    }
    
    var val = true
    var titles : [String] = []
    var dest : [CLLocation?] = []
    var date_commute : [String] = []
    var time_commute : [String] = []
    func readEvents()
    {
        if val{
            let eventStore = EKEventStore()
            let calendars = eventStore.calendars(for: .event)
            
            for calendar in calendars
            {
                    
                    let oneMonthAgo = NSDate(timeIntervalSinceNow: -30*24*3600)
                    let oneMonthAfter = NSDate(timeIntervalSinceNow: +30*24*3600)
                    
                    let predicate = eventStore.predicateForEvents(withStart: oneMonthAgo as Date, end: oneMonthAfter as Date, calendars: [calendar])
                    
                    let events = eventStore.events(matching: predicate)
                    
                    for event in events
                    {
                        if event.structuredLocation?.geoLocation?.coordinate != nil
                        {
                            titles.append(event.title)
                            dest.append(event.structuredLocation?.geoLocation)
                            time_commute.append(self.dateFormatter3.string(from: event.startDate! as Date))
                            date_commute.append(self.dateFormatter2.string(from: event.startDate! as Date))
                            print(event)
                        }
                     }
            }
            print(titles)
            print(dest)
            print(date_commute)
            print(time_commute)
            val = false
        }
    }
    
    func addDb(){
        var val = true
        if val{
        for i in 0..<titles.count{
            let insertCommute = self.commuteTable.insert(
                self.col.arrivalTime <- time_commute[i],
                self.col.dateOfCommute <- formatDate(date: date_commute[i]),
                self.col.destLat <- (dest[i]!.coordinate.latitude),
                self.col.destLong <- (dest[i]!.coordinate.longitude),
                self.col.eventName <- (titles[i]),
                self.col.srcLat <- (source!.coordinate.latitude),
                self.col.srcLong <- (source!.coordinate.longitude),
                self.col.isSrcCurrentLoc <- (true))
//            print(insertCommute)
            do {
                try self.database.run(insertCommute)
                print("INSERTED COMMUTE")
            } catch {
                print(error)
            }
        }
        val = false
     }
    }
    
    var database: Connection!
    var eventsio = [String]()
    @IBOutlet weak var integrateButton: UIButton!
    
    override func viewDidLoad() {
        do {
            let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileUrl = documentDirectory.appendingPathComponent("users").appendingPathExtension("sqlite3")
            let database = try Connection(fileUrl.path)
            self.database = database
        } catch {
            print(error)
        }
        calendar_view.appearance.headerMinimumDissolvedAlpha = 0.0
        
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyBest
        clManager.requestWhenInUseAuthorization()
        clManager.requestLocation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let query =  commuteTable.select(col.dateOfCommute)
        do{
            let dateTable =  try self.database.prepare(query)
            for i in dateTable
            {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM-dd-yyyy"
                var somedate = try i.get(col.dateOfCommute)
                somedate = formatDate2(date: somedate)
                if(!eventsio.contains(somedate))
                {
                    eventsio.append(somedate)
                }
                calendar_view.reloadData()
            }
        }
        catch{
            print("error")
        }
    }
    
    fileprivate lazy var dateFormatter2: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    fileprivate lazy var dateFormatter3: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter
    }()
    
    func formatDate(date: String) -> String {
        let dateTimeArray = date.components( separatedBy: "T")
        let dateArray = dateTimeArray[0].components(separatedBy: "-")
        return buildDate(dateArray: dateArray)
    }
    
    func formatDate2(date : String) -> String{
        let dateTimeArray = date.components(separatedBy: ",")
        var dateArray = dateTimeArray[0].components(separatedBy: " ")
        dateArray.append(dateTimeArray[1])
        return buildDate2(dateArray: dateArray)
    }
   
    func buildDate2(dateArray: [String]) ->String
    {
        func getMonthNumber(month: String) -> Int {
            switch month
            {
            case "Jan":
                let mon = 1
                return mon
            case "Feb":
                let mon = 2
                return mon
            case "Mar":
                let mon = 3
                return mon
            case "Apr":
                let mon =  4
                return mon
            case "May":
                let mon =  5
                return mon
            case "Jun":
                let mon =  6
                return mon
            case "Jul":
                let mon =  7
                return mon
            case "Aug":
                let mon =  8
                return mon

            case "Sep":
                let mon =  9
                return mon

            case "Oct":
                let mon =  10
                return mon

            case "Nov":
                let mon =  11
                return mon

            case "Dec":
                let mon =  12
                return mon

            default:
                let mon =  1
                return mon
            }
        }
        let i = getMonthNumber(month: dateArray[0])
        let year = dateArray[2]
        return Int(dateArray[1])! < 10 ? "\(year.dropFirst())-\(i)-0\(dateArray[1])" :
        "\(year.dropFirst())-\(i)-\(dateArray[1])"
    }
    
    func buildDate(dateArray: [String]) -> String{
        var month = ""
        switch dateArray[1] {
        case "01":
            month = "Jan"
        case "02":
            month = "Feb"
        case "03":
            month = "Mar"
        case "04":
            month = "Apr"
        case "05":
            month = "May"
        case "06":
            month = "Jun"
        case "07":
            month = "Jul"
        case "08":
            month = "Aug"
        case "09":
            month = "Sep"
        case "10":
            month = "Oct"
        case "11":
            month = "Nov"
        case "12":
            month = "Dec"
        default:
            month = "Mystery Month"
        }
        
        let day = Int(dateArray[2])

        return "\(month) \(day!), \(dateArray[0])"
    }
    
}

extension CalendarViewController:FSCalendarDataSource,FSCalendarDelegate{
    
    //fetching date
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        let navC = self.tabBarController!.viewControllers![0] as! UINavigationController
        let eventList = navC.viewControllers[0] as! EventListViewController
        eventList.queryDate = formatDate(date: (date.datatypeValue))
        print("query date from the calendar: \(formatDate(date: (date.datatypeValue)))")
        self.tabBarController!.selectedIndex = 0

    }
    
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        let dateString = self.dateFormatter2.string(from: date)
//        print(eventsio)
        if self.eventsio.contains(dateString) {
            return 1
        }
        return 0
    }
    
}

extension CalendarViewController: CLLocationManagerDelegate{
    
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
            
            self.source = getPlacemarks(location: self.currentLocation!)
            
        }
    }
    
    func getPlacemarks(location: CLLocation) -> MKPlacemark {
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
    
}
