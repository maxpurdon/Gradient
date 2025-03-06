import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage

class FirebaseManager {
    static let shared = FirebaseManager()
    
    private let db: Firestore
    private let storage: Storage
    
    // Collections
    private let projectsCollection = "projects"
    private let tasksCollection = "tasks"
    private let notesCollection = "notes"
    
    private init() {
        // Initialize Firebase
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        db = Firestore.firestore()
        storage = Storage.storage()
        
        // Enable offline persistence
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        db.settings = settings
    }
    
    // MARK: - Projects
    
    func observeProjects(completion: @escaping ([Project]) -> Void) {
        db.collection(projectsCollection)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching projects: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }
                
                let projects = documents.compactMap { Project.fromDictionary($0.data()) }
                completion(projects)
            }
    }
    
    func addProject(_ project: Project, completion: @escaping (Result<Void, Error>) -> Void) {
        let data = project.toDictionary()
        db.collection(projectsCollection).document(project.id).setData(data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func updateProject(_ project: Project, completion: @escaping (Result<Void, Error>) -> Void) {
        let data = project.toDictionary()
        db.collection(projectsCollection).document(project.id).updateData(data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func deleteProject(_ projectId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // First delete all tasks and notes related to this project
        let batch = db.batch()
        
        // Delete tasks
        db.collection(tasksCollection).whereField("projectId", isEqualTo: projectId).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            for document in snapshot?.documents ?? [] {
                batch.deleteDocument(document.reference)
            }
            
            // Delete notes and their attachments
            self.db.collection(self.notesCollection).whereField("projectId", isEqualTo: projectId).getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                for document in snapshot?.documents ?? [] {
                    batch.deleteDocument(document.reference)
                    
                    // Delete attachments in storage
                    if let noteData = document.data() as? [String: Any],
                       let attachments = noteData["attachments"] as? [[String: Any]] {
                        for attachment in attachments {
                            if let fileURL = attachment["fileURL"] as? String {
                                self.storage.reference(forURL: fileURL).delete(completion: nil)
                            }
                            if let thumbnailURL = attachment["thumbnailURL"] as? String {
                                self.storage.reference(forURL: thumbnailURL).delete(completion: nil)
                            }
                        }
                    }
                }
                
                // Finally delete the project
                batch.deleteDocument(self.db.collection(self.projectsCollection).document(projectId))
                
                // Commit the batch
                batch.commit { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    // MARK: - Tasks
    
    func observeTasks(forProject projectId: String, completion: @escaping ([Task]) -> Void) {
        db.collection(tasksCollection)
            .whereField("projectId", isEqualTo: projectId)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching tasks: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }
                
                let tasks = documents.compactMap { Task.fromDictionary($0.data()) }
                completion(tasks)
            }
    }
    
    func addTask(_ task: Task, completion: @escaping (Result<Void, Error>) -> Void) {
        let data = task.toDictionary()
        
        // Add task document
        db.collection(tasksCollection).document(task.id).setData(data) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Update project's tasks array
            self.db.collection(self.projectsCollection).document(task.projectId).updateData([
                "tasks": FieldValue.arrayUnion([task.id]),
                "updatedAt": Date().timeIntervalSince1970
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    func updateTask(_ task: Task, completion: @escaping (Result<Void, Error>) -> Void) {
        let data = task.toDictionary()
        db.collection(tasksCollection).document(task.id).updateData(data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                // Update project's updatedAt timestamp
                self.db.collection(self.projectsCollection).document(task.projectId).updateData([
                    "updatedAt": Date().timeIntervalSince1970
                ]) { _ in
                    completion(.success(()))
                }
            }
        }
    }
    
    func deleteTask(_ taskId: String, fromProject projectId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Delete task document
        db.collection(tasksCollection).document(taskId).delete { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Update project's tasks array
            self.db.collection(self.projectsCollection).document(projectId).updateData([
                "tasks": FieldValue.arrayRemove([taskId]),
                "updatedAt": Date().timeIntervalSince1970
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    // MARK: - Notes
    
    func observeNotes(forProject projectId: String, completion: @escaping ([Note]) -> Void) {
        db.collection(notesCollection)
            .whereField("projectId", isEqualTo: projectId)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching notes: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }
                
                let notes = documents.compactMap { Note.fromDictionary($0.data()) }
                completion(notes)
            }
    }
    
    func addNote(_ note: Note, completion: @escaping (Result<Void, Error>) -> Void) {
        let data = note.toDictionary()
        
        // Add note document
        db.collection(notesCollection).document(note.id).setData(data) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Update project's notes array
            self.db.collection(self.projectsCollection).document(note.projectId).updateData([
                "notes": FieldValue.arrayUnion([note.id]),
                "updatedAt": Date().timeIntervalSince1970
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    func updateNote(_ note: Note, completion: @escaping (Result<Void, Error>) -> Void) {
        let data = note.toDictionary()
        db.collection(notesCollection).document(note.id).updateData(data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                // Update project's updatedAt timestamp
                self.db.collection(self.projectsCollection).document(note.projectId).updateData([
                    "updatedAt": Date().timeIntervalSince1970
                ]) { _ in
                    completion(.success(()))
                }
            }
        }
    }
    
    func deleteNote(_ noteId: String, fromProject projectId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Get the note to find attachments
        db.collection(notesCollection).document(noteId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Delete attachments from storage
            if let data = snapshot?.data(),
               let attachments = data["attachments"] as? [[String: Any]] {
                for attachment in attachments {
                    if let fileURL = attachment["fileURL"] as? String {
                        self.storage.reference(forURL: fileURL).delete(completion: nil)
                    }
                    if let thumbnailURL = attachment["thumbnailURL"] as? String {
                        self.storage.reference(forURL: thumbnailURL).delete(completion: nil)
                    }
                }
            }
            
            // Delete note document
            self.db.collection(self.notesCollection).document(noteId).delete { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // Update project's notes array
                self.db.collection(self.projectsCollection).document(projectId).updateData([
                    "notes": FieldValue.arrayRemove([noteId]),
                    "updatedAt": Date().timeIntervalSince1970
                ]) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    // MARK: - Media Upload
    
    func uploadMedia(data: Data, type: Attachment.AttachmentType, completion: @escaping (Result<(fileURL: String, thumbnailURL: String?), Error>) -> Void) {
        let fileID = UUID().uuidString
        let storageRef = storage.reference()
        
        // Determine file path and extension
        let fileExtension: String
        let contentType: String
        
        switch type {
        case .image:
            fileExtension = "jpg"
            contentType = "image/jpeg"
        case .video:
            fileExtension = "mp4"
            contentType = "video/mp4"
        case .audio:
            fileExtension = "m4a"
            contentType = "audio/m4a"
        }
        
        let mediaPath = "attachments/\(fileID).\(fileExtension)"
        let mediaRef = storageRef.child(mediaPath)
        
        // Save file locally to "Graduation Project" folder
        saveMediaLocally(data: data, filename: "\(fileID).\(fileExtension)", type: type)
        
        // Upload to Firebase
        let metadata = StorageMetadata()
        metadata.contentType = contentType
        
        let uploadTask = mediaRef.putData(data, metadata: metadata) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            mediaRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url?.absoluteString else {
                    completion(.failure(NSError(domain: "FirebaseManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not get download URL"])))
                    return
                }
                
                // For images and videos, create a thumbnail
                if type == .image || type == .video {
                    self.createThumbnail(from: data, type: type) { thumbnailData in
                        if let thumbnailData = thumbnailData {
                            let thumbnailPath = "attachments/thumbnails/\(fileID).jpg"
                            let thumbnailRef = storageRef.child(thumbnailPath)
                            
                            let thumbnailMetadata = StorageMetadata()
                            thumbnailMetadata.contentType = "image/jpeg"
                            
                            thumbnailRef.putData(thumbnailData, metadata: thumbnailMetadata) { _, error in
                                if let error = error {
                                    // Just log the error but still return the main file URL
                                    print("Error uploading thumbnail: \(error.localizedDescription)")
                                    completion(.success((downloadURL, nil)))
                                    return
                                }
                                
                                thumbnailRef.downloadURL { url, error in
                                    if let error = error {
                                        print("Error getting thumbnail URL: \(error.localizedDescription)")
                                        completion(.success((downloadURL, nil)))
                                        return
                                    }
                                    
                                    completion(.success((downloadURL, url?.absoluteString)))
                                }
                            }
                        } else {
                            // No thumbnail, just return the main file URL
                            completion(.success((downloadURL, nil)))
                        }
                    }
                } else {
                    // No thumbnail needed for audio
                    completion(.success((downloadURL, nil)))
                }
            }
        }
        
        uploadTask.resume()
    }
    
    private func createThumbnail(from data: Data, type: Attachment.AttachmentType, completion: @escaping (Data?) -> Void) {
        // In a real app, we would generate thumbnails from images and videos
        // For now, just use the original image for image attachments
        if type == .image {
            completion(data)
        } else {
            // For videos, would generate a thumbnail from the first frame
            // For simplicity, just return nil
            completion(nil)
        }
    }
    
    private func saveMediaLocally(data: Data, filename: String, type: Attachment.AttachmentType) {
        let fileManager = FileManager.default
        
        // Create Graduation Project directory if it doesn't exist
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Could not access documents directory")
            return
        }
        
        let graduationProjectDirectory = documentsDirectory.appendingPathComponent("Graduation Project")
        
        if !fileManager.fileExists(atPath: graduationProjectDirectory.path) {
            do {
                try fileManager.createDirectory(at: graduationProjectDirectory, withIntermediateDirectories: true)
            } catch {
                print("Error creating Graduation Project directory: \(error.localizedDescription)")
                return
            }
        }
        
        // Create subfolder for media type
        let typeFolder: String
        switch type {
        case .image: typeFolder = "Images"
        case .video: typeFolder = "Videos"
        case .audio: typeFolder = "Audio"
        }
        
        let mediaTypeDirectory = graduationProjectDirectory.appendingPathComponent(typeFolder)
        
        if !fileManager.fileExists(atPath: mediaTypeDirectory.path) {
            do {
                try fileManager.createDirectory(at: mediaTypeDirectory, withIntermediateDirectories: true)
            } catch {
                print("Error creating media type directory: \(error.localizedDescription)")
                return
            }
        }
        
        // Save the file
        let fileURL = mediaTypeDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            print("Media saved locally to: \(fileURL.path)")
        } catch {
            print("Error saving media file: \(error.localizedDescription)")
        }
    }
}