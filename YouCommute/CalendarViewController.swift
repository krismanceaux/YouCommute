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


class CalendarViewController: UIViewController {
    
    @IBOutlet weak var calendar_view: FSCalendar!
    var database: Connection!
    public var events = [String]()
    
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let col = dbEntry()
        let commuteTable = Table("commute")
        let query =  commuteTable.select(col.dateOfCommute)
        do{
            let dateTable =  try self.database.prepare(query)
            for i in dateTable
            {
                var finaldates = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM-dd-yyyy"
                finaldates = dateFormatter.date(from: try i.get(col.dateOfCommute))!
                dateFormatter.dateFormat = "yyyy-MM-dd"
                if(!events.contains(dateFormatter.string(from: finaldates)))
                {
                    events.append(dateFormatter.string(from: finaldates))
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
    
    func formatDate(date: String) -> String {
        let dateTimeArray = date.components( separatedBy: "T")
        let dateArray = dateTimeArray[0].components(separatedBy: "-")
        return buildDate(dateArray: dateArray)
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
        
        return "\(month) \(dateArray[2]), \(dateArray[0])"
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
        
        if self.events.contains(dateString) {
            return 1
        }
        return 0
    }
    
}
