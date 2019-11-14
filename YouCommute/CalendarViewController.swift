//
//  ViewController.swift
//  Calander Test 2
//
//  Created by Pranav Saineni on 11/5/19.
//  Copyright © 2019 Pranav Saineni. All rights reserved.
//

import UIKit
import FSCalendar

class CalendarViewController: UIViewController {
    fileprivate weak var calendar: FSCalendar!
    

    override func viewDidLoad() {
        
        
        let calendar = FSCalendar(frame: CGRect(x: 0, y: 0, width: 320, height: 300))
        calendar.translatesAutoresizingMaskIntoConstraints = false
        calendar.dataSource = self
        calendar.delegate = self
        view.addSubview(calendar)
        
        
        //Apperence//
        calendar.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        calendar.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        calendar.heightAnchor.constraint(equalToConstant: view.frame.height).isActive = true
        calendar.widthAnchor.constraint(equalToConstant: view.frame.width).isActive = true
        calendar.allowsMultipleSelection = false
        
        ///
        calendar.appearance.headerMinimumDissolvedAlpha = 0.0
        calendar.clipsToBounds = true
        calendar.appearance.weekdayTextColor = UIColor.red
        calendar.appearance.headerTitleColor=UIColor.red
        calendar.appearance.selectionColor=UIColor.blue
//        calendar.register(FSCalendarCell.self, forCellReuseIdentifier: "CELL")
        
        self.calendar = calendar
    }
    
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
        self.tabBarController!.selectedIndex = 0
    }
    
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        return 1
    }
}
   
