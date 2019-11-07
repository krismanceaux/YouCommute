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
        calendar.allowsMultipleSelection = true
        
        ///
        calendar.appearance.headerMinimumDissolvedAlpha = 0.0
        calendar.clipsToBounds = true
        calendar.appearance.weekdayTextColor = UIColor.red
        calendar.appearance.headerTitleColor=UIColor.red
        calendar.appearance.selectionColor=UIColor.blue
//        calendar.register(FSCalendarCell.self, forCellReuseIdentifier: "CELL")
        
        self.calendar = calendar
    }
   
    
}

extension CalendarViewController:FSCalendarDataSource,FSCalendarDelegate{
    
    //fetching date
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        print(date)
    }
    
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        return 1
    }
}
   
