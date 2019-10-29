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
    
    var eventName: String
    var source: MKMapItem?
    var destination: MKMapItem?
    var request: MKDirections.Request
    var directions: MKDirections
    
    init(srcLatitude:Double, srcLongitude:Double, destLatitude: Double, destLongitude: Double, eventName: String) {
        self.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(exactly: srcLatitude)!, longitude: CLLocationDegrees(exactly: srcLongitude)!)))
        self.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(exactly: destLatitude)!, longitude: CLLocationDegrees(exactly: destLongitude)!)))
        
        self.request = MKDirections.Request()
        self.request.source = self.source
        self.request.destination = self.destination
        self.request.transportType = .automobile
        
        self.directions = MKDirections(request: self.request)
        self.eventName = eventName
    }
}


class EventListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {
    
    
    var commutes: [Commute] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // DUMMY DATA
        
        commutes.append(Commute(srcLatitude: 29.6829, srcLongitude: -95.2876, destLatitude: 29.6499, destLongitude: -95.1784, eventName: "towards ellington"))
        
        commutes.append(Commute(srcLatitude: 29.6499, srcLongitude: -95.1784, destLatitude: 29.6060, destLongitude: -95.1266, eventName: "some neighborhood"))
    
        commutes.append(Commute(srcLatitude: 29.6060, srcLongitude: -95.1266, destLatitude: 29.5914, destLongitude: -95.1015, eventName: "HEB"))
        
        commutes.append(Commute(srcLatitude: 29.5914, srcLongitude: -95.1015, destLatitude: 29.5839, destLongitude: -95.1000, eventName: "Boeing"))
        
        commutes.append(Commute(srcLatitude: 29.5839, srcLongitude: -95.1000, destLatitude: 29.8721, destLongitude: -95.5557, eventName: "Houston"))

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



}

