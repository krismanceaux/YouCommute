//
//  NotificationManager.swift
//  YouCommute
//
//  Created by Kristopher Manceaux on 12/3/19.
//  Copyright © 2019 Kristopher Manceaux. All rights reserved.
//

import Foundation
import UserNotifications

class NotificationManager: NSObject{
    
    func sendNotification(title: String, subTitle: String, body: String, badge: Int?, delayUntilDateTime: DateComponents){
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = title
        notificationContent.subtitle = subTitle
        notificationContent.body = body
        
        let delayTimeTrigger = UNCalendarNotificationTrigger(dateMatching: delayUntilDateTime, repeats: false)
        
        notificationContent.sound = .default
        
        UNUserNotificationCenter.current().delegate = self
        
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: notificationContent, trigger: delayTimeTrigger)
        
        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
}

extension NotificationManager: UNUserNotificationCenterDelegate{
   
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let identifier = response.actionIdentifier
        
        switch identifier{
        case UNNotificationDismissActionIdentifier:
            print("Dismissed")
            completionHandler()
        case UNNotificationDefaultActionIdentifier:
            print("The user opened the app")
            completionHandler()
        default:
            print("default case")
        }
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Notification is about to be presented")
        completionHandler([.badge, .sound, .alert])
    }
}
