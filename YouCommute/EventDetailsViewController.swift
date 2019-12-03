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

class EventDetailsViewController: UIViewController, MFMessageComposeViewControllerDelegate {
    
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
    
    
    var commute: Commute?
    var travelTime: Double = 0.0
    let composeVC = MFMessageComposeViewController()
    
    @IBOutlet weak var whenToLeave: UILabel!
    @IBOutlet weak var dateOfCommute: UITextField!
    @IBOutlet weak var arrivalTime: UITextField!
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
        self.whenToLeave.text = formatTime(time: self.travelTime)
        
    }
    
    func showTextMessage(){
        if MFMessageComposeViewController.canSendText() {
            self.composeVC.messageComposeDelegate = self
            
            // Configure the fields of the interface.
            //self.composeVC.recipients = ["4085551212"]
            self.composeVC.body = "My drive to \(self.commute?.destination?.name ?? "the destination") will take \(self.travelTime) seconds. Sent from YouCommute."
            
            
            // Present the view controller modally.
            self.present(self.composeVC, animated: true, completion: nil)
            
        } else {
            print("SMS services are not available")
        }
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
        
        sheet.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        
        self.present(sheet, animated: true, completion: nil)
    }
    
    
//    @IBAction func openActionSheet(_ sender: UIBarButtonItem) {
//
//    }
    
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
        
        var leaveHour = arrivalHour!
        var leaveMin = arrivalMinutes!
        for _ in 0..<(Int(minutes) + 60 * Int(hours)){
            leaveMin -= 1
            if leaveMin < 0{
                leaveMin = 59
                leaveHour-=1
            }
            if leaveHour < 1{
                leaveHour=12
                if time1Arr![1] == "AM"{
                    time1Arr![1] = "PM"
                }
                else{
                    time1Arr![1] = "AM"
                }
            }
            
        }
        
        if leaveMin < 10{
            return "\(Int(leaveHour)):0\(Int(leaveMin)) \(time1Arr![1])"
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
