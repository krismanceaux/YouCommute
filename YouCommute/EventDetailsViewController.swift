//
//  EventDetailsViewController.swift
//  YouCommute
//
//  Created by Kristopher Manceaux on 10/20/19.
//  Copyright © 2019 Kristopher Manceaux. All rights reserved.
//

import UIKit
import MapKit

class EventDetailsViewController: UIViewController {

    var commute: Commute?
    var travelTime: Double = 0.0
    
    @IBOutlet weak var whenToLeave: UILabel!
    @IBOutlet weak var dateOfCommute: UILabel!
    @IBOutlet weak var arrivalTime: UILabel!
    @IBOutlet weak var eventName: UILabel!
    @IBOutlet weak var toAddress: UILabel!
    @IBOutlet weak var fromAddress: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.dateOfCommute.text = commute!.dateOfCommute
        self.arrivalTime.text = commute!.arrivalTime
        self.eventName.text = commute!.eventName
        self.toAddress.text = commute!.destination?.placemark.title
        self.fromAddress.text = commute!.source?.placemark.title
        self.whenToLeave.text = formatTime(time: self.travelTime)
        
    }
    @IBAction func openActionSheet(_ sender: UIBarButtonItem) {
        // Function body goes here
        let sheet = UIAlertController(title: "Actions", message: "Select one", preferredStyle: .actionSheet)
        
        sheet.addAction(UIAlertAction(title: "Route Directions", style: .default, handler: { _ in
            let mapItem = MKMapItem(placemark: self.commute!.destination!.placemark)
            let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
            mapItem.openInMaps(launchOptions: launchOptions)
        }))
        
        sheet.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        
        self.present(sheet, animated: true, completion: nil)
    }
    
    func formatTime(time: Double) -> String {
        // get the number of hours
        let hours = floor(time / 3600)
        var remainingSeconds = time - (3600 * hours)
        // get the number of minutes
        let minutes = floor(remainingSeconds / 60)
        remainingSeconds = remainingSeconds - (60 * minutes)

        var time1Arr = commute?.arrivalTime.split(separator: " ")
        let timeArr = time1Arr![0].split(separator: ":")
        let arrivalHour = Double(timeArr[0])
        let arrivalMinutes = Double(timeArr[1])
        
        var leaveHour = arrivalHour! - hours
        var leaveMin = arrivalMinutes! - minutes
        if leaveMin < 0{
            leaveMin = 60 - abs(leaveMin)
            leaveHour -= 1
        }
        if leaveHour < 0 {
            leaveHour = 12 - abs(leaveHour)
            if time1Arr![1] == "AM"{
                time1Arr![1] = "PM"
            }
            else{
                time1Arr![1] = "AM"
            }
        }
        return "\(Int(leaveHour)):\(Int(leaveMin)) \(time1Arr![1])"
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
