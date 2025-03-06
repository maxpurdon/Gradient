//
//  Attachment.swift
//  Gradient
//
//  Created by Andrew Purdon on 06/03/2025.
//


import Foundation
import CoreLocation

struct Attachment: Codable {
    enum AttachmentType: String, Codable {
        case image
        case video
        case audio
    }
    
    let id: String
    let type: AttachmentType
    let fileURL: String
    let thumbnailURL: String?
    let createdAt: Date
    
    init(id: String = UUID().uuidString,
         type: AttachmentType,
         fileURL: String,
         thumbnailURL: String? = nil,
         createdAt: Date = Date()) {
        self.id = id
        self.type = type
        self.fileURL = fileURL
        self.thumbnailURL = thumbnailURL
        self.createdAt = createdAt
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "type": type.rawValue,
            "fileURL": fileURL,
            "createdAt": createdAt.timeIntervalSince1970
        ]
        
        if let thumbnailURL = thumbnailURL {
            dict["thumbnailURL"] = thumbnailURL
        }
        
        return dict
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> Attachment? {
        guard
            let id = dict["id"] as? String,
            let typeRaw = dict["type"] as? String,
            let type = AttachmentType(rawValue: typeRaw),
            let fileURL = dict["fileURL"] as? String,
            let createdAtTimestamp = dict["createdAt"] as? TimeInterval
        else { return nil }
        
        return Attachment(
            id: id,
            type: type,
            fileURL: fileURL,
            thumbnailURL: dict["thumbnailURL"] as? String,
            createdAt: Date(timeIntervalSince1970: createdAtTimestamp)
        )
    }
}

struct Note: Codable {
    let id: String
    var title: String?
    var content: String
    var attachments: [Attachment]
    var location: CLLocationCoordinate2D?
    var projectId: String
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString,
         title: String? = nil,
         content: String,
         attachments: [Attachment] = [],
         location: CLLocationCoordinate2D? = nil,
         projectId: String,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.attachments = attachments.count > 4 ? Array(attachments.prefix(4)) : attachments
        self.location = location
        self.projectId = projectId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, title, content, attachments, projectId, createdAt, updatedAt
        case latitude, longitude
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        attachments = try container.decode([Attachment].self, forKey: .attachments)
        projectId = try container.decode(String.self, forKey: .projectId)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        // Handle coordinate
        if let latitude = try container.decodeIfPresent(Double.self, forKey: .latitude),
           let longitude = try container.decodeIfPresent(Double.self, forKey: .longitude) {
            location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        } else {
            location = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encode(attachments, forKey: .attachments)
        try container.encode(projectId, forKey: .projectId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        
        // Handle coordinate
        if let location = location {
            try container.encode(location.latitude, forKey: .latitude)
            try container.encode(location.longitude, forKey: .longitude)
        }
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "content": content,
            "attachments": attachments.map { $0.toDictionary() },
            "projectId": projectId,
            "createdAt": createdAt.timeIntervalSince1970,
            "updatedAt": updatedAt.timeIntervalSince1970
        ]
        
        if let title = title {
            dict["title"] = title
        }
        
        if let location = location {
            dict["latitude"] = location.latitude
            dict["longitude"] = location.longitude
        }
        
        return dict
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> Note? {
        guard
            let id = dict["id"] as? String,
            let content = dict["content"] as? String,
            let projectId = dict["projectId"] as? String,
            let createdAtTimestamp = dict["createdAt"] as? TimeInterval,
            let updatedAtTimestamp = dict["updatedAt"] as? TimeInterval,
            let attachmentsDict = dict["attachments"] as? [[String: Any]]
        else { return nil }
        
        let attachments = attachmentsDict.compactMap { Attachment.fromDictionary($0) }
        
        var location: CLLocationCoordinate2D? = nil
        if let latitude = dict["latitude"] as? Double,
           let longitude = dict["longitude"] as? Double {
            location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        
        return Note(
            id: id,
            title: dict["title"] as? String,
            content: content,
            attachments: attachments,
            location: location,
            projectId: projectId,
            createdAt: Date(timeIntervalSince1970: createdAtTimestamp),
            updatedAt: Date(timeIntervalSince1970: updatedAtTimestamp)
        )
    }
}