//
//  NotificationManager.swift
//  Gradient
//
//  Created by Andrew Purdon on 07/03/2025.
//
import UIKit
import UserNotifications
class NotificationManager {
    static let shared = NotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {}
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
            
            if let error = error {
                print("Error requesting notification authorization: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNotification(for id: String, title: String, body: String, date: Date) {
        // Request authorization first
        requestAuthorization { granted in
            guard granted else {
                print("Notification authorization denied")
                return
            }
            
            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            
            // Create trigger
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            // Create request
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            
            // Add request
            self.notificationCenter.add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                } else {
                    print("Notification scheduled for \(date)")
                }
            }
        }
    }
    
    func cancelNotification(for id: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
        print("Notification canceled for ID: \(id)")
    }
}
