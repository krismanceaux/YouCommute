//
//  SecondViewController.swift
//  YouCommute
//
//  Created by Kristopher Manceaux on 10/20/19.
//  Copyright © 2019 Kristopher Manceaux. All rights reserved.
//

import UIKit
import MapKit

//  <column>  :  <data type>
// event name : String
// from address: string
// from coordinates: (double, double) -> could be a lookup table
// to address : string
// to coordinates: (double, double) -> could be a lookup table
// arrival time: string
// date of commute: string


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


class EventListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var commutes: [Commute] = []
    var travelTimes: [Double] = []
    var selectedCommute: Commute?
    var selectedTime: Double?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    func getETA(direction: MKDirections, cell: UITableViewCell, indexPath:IndexPath) {
        direction.calculateETA { (response, error) in
            guard error == nil, let response = response else {return}
            let travelTimeLabel = cell.viewWithTag(1) as! UILabel
            let tTime = response.expectedTravelTime
            self.travelTimes.append(tTime)
            travelTimeLabel.text = self.formatTime(time: tTime)
        }
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

    override func viewDidAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toEventDetails" {
            let detailsVC = segue.destination as! EventDetailsViewController
            detailsVC.commute = self.selectedCommute
            detailsVC.travelTime = self.selectedTime!
        }
    }

}


extension EventListViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.selectedCommute = commutes[indexPath.row]
        self.selectedTime = travelTimes[indexPath.row]
        performSegue(withIdentifier: "toEventDetails", sender: self)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
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
        return cell
    }
}
