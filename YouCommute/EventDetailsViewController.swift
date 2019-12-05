//
//  EventDetailsViewController.swift
//  YouCommute
//
//  Created by Kristopher Manceaux on 10/20/19.
//  Copyright © 2019 Kristopher Manceaux. All rights reserved.
//

import UIKit
import MapKit
import MessageUI
import CoreLocation
import SQLite

class EventDetailsViewController: UIViewController, MFMessageComposeViewControllerDelegate {
    
    var commute: Commute?
    var travelTime: Double = 0.0
    let clManager = CLLocationManager()
    var currentLocation: CLLocation?
    
    let commuteTable = Table("commute")
    let columns = dbEntry()
    var database: Connection!
    var indexPath: IndexPath?

    
    
    @IBOutlet weak var whenToLeave: UILabel!
    @IBOutlet weak var dateOfCommute: UILabel!
    @IBOutlet weak var arrivalTime: UILabel!
    @IBOutlet weak var eventName: UILabel!
    @IBOutlet weak var toAddress: UITextField!
    @IBOutlet weak var fromAddress: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.dateOfCommute.text = commute!.dateOfCommute
        self.arrivalTime.text = commute!.arrivalTime
        self.eventName.text = commute!.eventName
        self.toAddress.text = commute!.destination?.placemark.title
        self.fromAddress.text = commute!.source?.placemark.title
        self.whenToLeave.text = getTimeToLeave(time: self.travelTime, arrivalTime: nil)
        
        
        // get user location
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyBest
        //clManager.requestWhenInUseAuthorization()
        clManager.requestLocation()
        
        
        do {
           let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
           let fileUrl = documentDirectory.appendingPathComponent("users").appendingPathExtension("sqlite3")
           let database = try Connection(fileUrl.path)
           self.database = database
       } catch {
           print(error)
       }
    }
    
    func showTextMessage(){
        if MFMessageComposeViewController.canSendText() {

            // TODO
            // get current location clplacemark
            
            
            // convert to mapkit placemark
            let eventListVC = EventListViewController()
            let placemark = eventListVC.getPlacemark(location: self.currentLocation!)
            let currentCommute = Commute(source: placemark, destination: (commute?.destination!.placemark)!, eventName: commute!.eventName, arrivalTime: commute!.arrivalTime, dateOfCommute: commute!.dateOfCommute)

            // call getETA function
            currentCommute.directions.calculateETA { (response, error) in
                guard error == nil, let response = response else {return}
                
                print("In text \(response.expectedTravelTime)")
                let currentDriveTime = self.formatTravelTime(timeInSeconds: response.expectedTravelTime)
                let composeVC = MFMessageComposeViewController()
                composeVC.messageComposeDelegate = self
                // Configure the fields of the interface.
                //self.composeVC.recipients = ["4085551212"]
                if currentDriveTime.0 > 1  {
                    composeVC.body = "I am \(Int(currentDriveTime.0)) hours and \(Int(currentDriveTime.1)) minutes away from \(self.commute?.destination?.name ?? "our destination")!\nSent from YouCommute."
                }
                else if currentDriveTime.0 == 1 {
                    composeVC.body = "I am \(Int(currentDriveTime.0)) hour and \(Int(currentDriveTime.1)) minutes away from \(self.commute?.destination?.name ?? "our destination")!\nSent from YouCommute."
                }
                else {
                    composeVC.body = "I am \(Int(currentDriveTime.1)) minutes away from \(self.commute?.destination?.name ?? "our destination")!\nSent from YouCommute."
                }
                
                // Present the view controller modally.
                self.present(composeVC, animated: true, completion: nil)
                
            }
            
            
            

        } else {
            print("SMS services are not available")
        }
    }
    
    func deleteCommute(){
        print("Inside delete commute")
        let alert = UIAlertController(title: "Delete", message: "Are you sure you want to delete this selection?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (_) in
            let commuteToDelete = self.commuteTable.filter(self.columns.eventName == self.commute!.eventName).filter(self.columns.dateOfCommute == self.commute!.dateOfCommute)
            do{
                try self.database.run(commuteToDelete.delete())
            } catch {
                print("Delete failed: \(error)")
            }
            
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)

    }
    
    
    @IBAction func listButtonUIBar(_ sender: Any) {
        // Function body goes here
        let sheet = UIAlertController(title: "Actions", message: "Select one", preferredStyle: .actionSheet)
        
        sheet.addAction(UIAlertAction(title: "Route Directions", style: .default, handler: { _ in
            let mapItem = MKMapItem(placemark: self.commute!.destination!.placemark)
            let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
            mapItem.openInMaps(launchOptions: launchOptions)
        }))
        
        sheet.addAction(UIAlertAction(title: "Send Text Status", style: .default, handler: { (_) in
            self.showTextMessage()
          
        }))
        
        sheet.addAction(UIAlertAction(title: "Delete Commute", style: .default, handler: { (_) in
            
            // call method to delete commute
            self.deleteCommute()
            
        }))
        
        
        sheet.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        
        self.present(sheet, animated: true, completion: nil)
    }
       
    func formatTravelTime(timeInSeconds: Double) -> (Double, Double, Double){
        // get the number of hours
        let hours = floor(timeInSeconds / 3600)
        var remainingSeconds = timeInSeconds - (3600 * hours)
        // get the number of minutes
        let minutes = floor(remainingSeconds / 60)
        remainingSeconds = remainingSeconds - (60 * minutes)
        
        return (hours, minutes, remainingSeconds)
    }
    
    func getTimeToLeave(time: Double, arrivalTime: String?) -> String {
        print(time)
        
        // converts seconds to (hour, minute, second)
        let hr_min_sec = formatTravelTime(timeInSeconds: time)
        let hours = hr_min_sec.0
        let minutes = hr_min_sec.1
        
        // Split the arrival time to an array to get rid of the AM / PM
        var time1Arr = [String.SubSequence]()
        if let commute = self.commute {
            time1Arr = commute.arrivalTime.split(separator: " ")
        }
        else{
            time1Arr = arrivalTime!.split(separator: " ")
        }
       
        
        // split the arrival time at the : to separate hour and minutes and parse the numbers from string to double
        let timeArr = time1Arr[0].split(separator: ":")
        let arrivalHour = Double(timeArr[0])
        let arrivalMinutes = Double(timeArr[1])
        
        // define new variables to hold the leave hour and minute to be used in the next operation
        var leaveHour = arrivalHour!
        var leaveMin = arrivalMinutes!
        // iterate back like a clock
        // we are iterating back by the minute, so we convert the hours+minutes into just minutes
        for _ in 0..<(Int(minutes) + 60 * Int(hours)){
            leaveMin -= 1
            if leaveMin < 0{
                leaveMin = 59
                leaveHour-=1
            }
            if leaveHour < 1{
                leaveHour=12
                if time1Arr[1] == "AM"{
                    time1Arr[1] = "PM"
                }
                else{
                    time1Arr[1] = "AM"
                }
            }
            
        }
        if leaveMin < 10{
            return "\(Int(leaveHour)):0\(Int(leaveMin)) \(time1Arr[1])"
        }
        return "\(Int(leaveHour)):\(Int(leaveMin)) \(time1Arr[1])"
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        switch result{
        case .cancelled:
            dismiss(animated: true, completion: nil)
        case .failed:
            dismiss(animated: true, completion: nil)
        case .sent:
            dismiss(animated: true, completion: nil)
        default:
            dismiss(animated: true, completion: nil)
        }
    }
    
    
    
}

// CORE LOCATION MANAGER DELEGATE FUNCTIONS
// Using the core location library forces us to implement these functions
extension EventDetailsViewController: CLLocationManagerDelegate{
    
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
