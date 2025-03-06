//
//  Project.swift
//  Gradient
//
//  Created by Andrew Purdon on 06/03/2025.
//


import Foundation
import UIKit

struct Project: Codable {
    enum Status: String, Codable, CaseIterable {
        case notStarted = "Not Started"
        case planning = "Planning"
        case inProgress = "In Progress"
        case testing = "Testing"
        case completed = "Completed"
        
        var color: UIColor {
            switch self {
            case .notStarted: return .systemGray
            case .planning: return .systemBlue
            case .inProgress: return .systemOrange
            case .testing: return .systemPurple
            case .completed: return .systemGreen
            }
        }
    }
    
    let id: String
    var name: String
    var description: String
    var status: Status
    var workshops: [String]
    var materialsNeeded: [String]
    var materialsFound: [String]
    var tasks: [String] // Reference IDs to tasks
    var notes: [String] // Reference IDs to notes
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString, 
         name: String, 
         description: String = "", 
         status: Status = .notStarted,
         workshops: [String] = [],
         materialsNeeded: [String] = [],
         materialsFound: [String] = [],
         tasks: [String] = [],
         notes: [String] = [],
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.status = status
        self.workshops = workshops
        self.materialsNeeded = materialsNeeded
        self.materialsFound = materialsFound
        self.tasks = tasks
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "description": description,
            "status": status.rawValue,
            "workshops": workshops,
            "materialsNeeded": materialsNeeded,
            "materialsFound": materialsFound,
            "tasks": tasks,
            "notes": notes,
            "createdAt": createdAt.timeIntervalSince1970,
            "updatedAt": updatedAt.timeIntervalSince1970
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> Project? {
        guard 
            let id = dict["id"] as? String,
            let name = dict["name"] as? String,
            let description = dict["description"] as? String,
            let statusRaw = dict["status"] as? String,
            let status = Status(rawValue: statusRaw),
            let workshops = dict["workshops"] as? [String],
            let materialsNeeded = dict["materialsNeeded"] as? [String],
            let materialsFound = dict["materialsFound"] as? [String],
            let tasks = dict["tasks"] as? [String],
            let notes = dict["notes"] as? [String],
            let createdAtTimestamp = dict["createdAt"] as? TimeInterval,
            let updatedAtTimestamp = dict["updatedAt"] as? TimeInterval
        else { return nil }
        
        return Project(
            id: id,
            name: name,
            description: description,
            status: status,
            workshops: workshops,
            materialsNeeded: materialsNeeded,
            materialsFound: materialsFound,
            tasks: tasks,
            notes: notes,
            createdAt: Date(timeIntervalSince1970: createdAtTimestamp),
            updatedAt: Date(timeIntervalSince1970: updatedAtTimestamp)
        )
    }
}