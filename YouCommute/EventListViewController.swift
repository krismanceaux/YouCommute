//
//  SecondViewController.swift
//  YouCommute
//
//  Created by Kristopher Manceaux on 10/20/19.
//  Copyright © 2019 Kristopher Manceaux. All rights reserved.
//

import UIKit
import MapKit

struct Commute{
    
    // Arrival time
    // Date of Commute
    // source
    // destination
    // event name
    
    var eventName: String
    var source: MKMapItem?
    var destination: MKMapItem?
    //var request: MKDirections.Request
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


class EventListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {
    
    @IBOutlet weak var tableView: UITableView!
    
    var commutes: [Commute] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source
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

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath)
        
        getETA(direction: commutes[indexPath.row].directions, cell: cell, indexPath: indexPath)
        let eventNameLabel = cell.viewWithTag(2) as! UILabel
        eventNameLabel.text = commutes[indexPath.row].eventName
        return cell
    }
    
    func getETA(direction: MKDirections, cell: UITableViewCell, indexPath:IndexPath) {
        direction.calculateETA { (response, error) in
            guard error == nil, let response = response else {return}
            let travelTimeLabel = cell.viewWithTag(1) as! UILabel
            travelTimeLabel.text = self.formatTime(time: response.expectedTravelTime)
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

}

