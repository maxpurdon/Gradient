//
//  Task.swift
//  Gradient
//
//  Created by Andrew Purdon on 06/03/2025.
//


import Foundation

struct Task: Codable {
    enum Status: String, Codable, CaseIterable {
        case notStarted = "Not Started"
        case inProgress = "In Progress"
        case completed = "Completed"
    }
    
    let id: String
    var title: String
    var status: Status
    var dueDate: Date?
    var notifyUser: Bool
    var notificationDate: Date?
    var projectId: String
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString,
         title: String,
         status: Status = .notStarted,
         dueDate: Date? = nil,
         notifyUser: Bool = false,
         notificationDate: Date? = nil,
         projectId: String,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.status = status
        self.dueDate = dueDate
        self.notifyUser = notifyUser
        self.notificationDate = notificationDate
        self.projectId = projectId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "title": title,
            "status": status.rawValue,
            "notifyUser": notifyUser,
            "projectId": projectId,
            "createdAt": createdAt.timeIntervalSince1970,
            "updatedAt": updatedAt.timeIntervalSince1970
        ]
        
        if let dueDate = dueDate {
            dict["dueDate"] = dueDate.timeIntervalSince1970
        }
        
        if let notificationDate = notificationDate {
            dict["notificationDate"] = notificationDate.timeIntervalSince1970
        }
        
        return dict
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> Task? {
        guard
            let id = dict["id"] as? String,
            let title = dict["title"] as? String,
            let statusRaw = dict["status"] as? String,
            let status = Status(rawValue: statusRaw),
            let notifyUser = dict["notifyUser"] as? Bool,
            let projectId = dict["projectId"] as? String,
            let createdAtTimestamp = dict["createdAt"] as? TimeInterval,
            let updatedAtTimestamp = dict["updatedAt"] as? TimeInterval
        else { return nil }
        
        var dueDate: Date? = nil
        if let dueDateTimestamp = dict["dueDate"] as? TimeInterval {
            dueDate = Date(timeIntervalSince1970: dueDateTimestamp)
        }
        
        var notificationDate: Date? = nil
        if let notificationDateTimestamp = dict["notificationDate"] as? TimeInterval {
            notificationDate = Date(timeIntervalSince1970: notificationDateTimestamp)
        }
        
        return Task(
            id: id,
            title: title,
            status: status,
            dueDate: dueDate,
            notifyUser: notifyUser,
            notificationDate: notificationDate,
            projectId: projectId,
            createdAt: Date(timeIntervalSince1970: createdAtTimestamp),
            updatedAt: Date(timeIntervalSince1970: updatedAtTimestamp)
        )
    }
}