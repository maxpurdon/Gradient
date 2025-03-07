//
//  NotesViewController.swift
//  Gradient
//
//  Created by Andrew Purdon on 06/03/2025.
//


import UIKit
import CoreLocation
import AVFoundation
import Photos

class NotesViewController: UIViewController {
    
    // MARK: - Properties
    private let tableView = UITableView()
    private let addButton = UIButton(type: .system)
    private let projectId: String
    private var notes: [Note] = []
    
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocationCoordinate2D?
    
    // MARK: - Initializers
    init(projectId: String) {
        self.projectId = projectId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        setupLocationManager()
        observeNotes()
    }
    
    // MARK: - Setup Methods
    private func setupViews() {
        view.backgroundColor = .systemBackground
        
        // TableView setup
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(NoteCell.self, forCellReuseIdentifier: "NoteCell")
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        view.addSubview(tableView)
        
        // Add button setup
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addButton.tintColor = .systemBlue
        addButton.contentVerticalAlignment = .fill
        addButton.contentHorizontalAlignment = .fill
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        view.addSubview(addButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            addButton.widthAnchor.constraint(equalToConstant: 60),
            addButton.heightAnchor.constraint(equalToConstant: 60),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Data Methods
    private func observeNotes() {
        FirebaseManager.shared.observeNotes(forProject: projectId) { [weak self] notes in
            guard let self = self else { return }
            self.notes = notes.sorted(by: { $0.createdAt > $1.createdAt }) // Newest first
            self.tableView.reloadData()
        }
    }
    
    // MARK: - Action Methods
    @objc private func addButtonTapped() {
        let addNoteVC = AddNoteViewController(projectId: projectId)
        let navigationController = UINavigationController(rootViewController: addNoteVC)
        present(navigationController, animated: true)
    }
    
    private func showNoteOptions(forNote note: Note, sender: UIView) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }
        
        // View note
        alertController.addAction(UIAlertAction(title: "View Note", style: .default) { [weak self] _ in
            self?.viewNote(note)
        })
        
        // Edit note
        alertController.addAction(UIAlertAction(title: "Edit Note", style: .default) { [weak self] _ in
            self?.editNote(note)
        })
        
        // Delete note
        alertController.addAction(UIAlertAction(title: "Delete Note", style: .destructive) { [weak self] _ in
            self?.confirmDeleteNote(note)
        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alertController, animated: true)
    }
    
    private func viewNote(_ note: Note) {
        let viewNoteVC = ViewNoteViewController(note: note)
        let navigationController = UINavigationController(rootViewController: viewNoteVC)
        present(navigationController, animated: true)
    }
    
    private func editNote(_ note: Note) {
        let editNoteVC = AddNoteViewController(projectId: projectId, editingNote: note)
        let navigationController = UINavigationController(rootViewController: editNoteVC)
        present(navigationController, animated: true)
    }
    
    private func confirmDeleteNote(_ note: Note) {
        let alertController = UIAlertController(
            title: "Delete Note",
            message: "Are you sure you want to delete this note?",
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alertController.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteNote(note)
        })
        
        present(alertController, animated: true)
    }
    
    private func deleteNote(_ note: Note) {
        FirebaseManager.shared.deleteNote(note.id, fromProject: projectId) { [weak self] result in
            if case .failure(let error) = result {
                self?.showAlert(message: "Failed to delete note: \(error.localizedDescription)")
            }
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension NotesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell", for: indexPath) as? NoteCell else {
            return UITableViewCell()
        }
        
        let note = notes[indexPath.row]
        cell.configure(with: note)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let note = notes[indexPath.row]
        viewNote(note)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let note = notes[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
            self?.confirmDeleteNote(note)
            completion(true)
        }
        deleteAction.backgroundColor = .systemRed
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] (_, _, completion) in
            self?.editNote(note)
            completion(true)
        }
        editAction.backgroundColor = .systemBlue
        
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }
}

// MARK: - CLLocationManagerDelegate
extension NotesViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
}

// MARK: - NoteCell
class NoteCell: UITableViewCell {
    
    // MARK: - Properties
    private let titleLabel = UILabel()
    private let contentLabel = UILabel()
    private let dateLabel = UILabel()
    private let attachmentsView = UIStackView()
    private let locationLabel = UILabel()
    
    // MARK: - Initializers
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    private func setupViews() {
        // Title Label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.numberOfLines = 1
        contentView.addSubview(titleLabel)
        
        // Content Label
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.font = UIFont.systemFont(ofSize: 15)
        contentLabel.numberOfLines = 2
        contentLabel.textColor = .label
        contentView.addSubview(contentLabel)
        
        // Date Label
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = UIFont.systemFont(ofSize: 12)
        dateLabel.textColor = .secondaryLabel
        contentView.addSubview(dateLabel)
        
        // Attachments View
        attachmentsView.translatesAutoresizingMaskIntoConstraints = false
        attachmentsView.axis = .horizontal
        attachmentsView.spacing = 8
        attachmentsView.distribution = .fillEqually
        contentView.addSubview(attachmentsView)
        
        // Location Label
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        locationLabel.font = UIFont.systemFont(ofSize: 12)
        locationLabel.textColor = .secondaryLabel
        contentView.addSubview(locationLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            contentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            attachmentsView.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 8),
            attachmentsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            attachmentsView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            attachmentsView.heightAnchor.constraint(equalToConstant: 44),
            
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dateLabel.topAnchor.constraint(equalTo: attachmentsView.bottomAnchor, constant: 8),
            dateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            locationLabel.leadingAnchor.constraint(greaterThanOrEqualTo: dateLabel.trailingAnchor, constant: 16),
            locationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            locationLabel.centerYAnchor.constraint(equalTo: dateLabel.centerYAnchor)
        ])
    }
    
    // MARK: - Configuration
    func configure(with note: Note) {
        // Configure title
        titleLabel.text = note.title ?? "Untitled Note"
        
        // Configure content
        contentLabel.text = note.content
        
        // Configure date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        dateLabel.text = formatter.string(from: note.createdAt)
        
        // Clear previous attachments
        attachmentsView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add attachment thumbnails (up to 4)
        if !note.attachments.isEmpty {
            for attachment in note.attachments.prefix(4) {
                let thumbnailView = UIImageView()
                thumbnailView.contentMode = .scaleAspectFill
                thumbnailView.clipsToBounds = true
                thumbnailView.layer.cornerRadius = 4
                thumbnailView.backgroundColor = .systemGray5
                
                // Add icon based on attachment type
                let icon: UIImage?
                switch attachment.type {
                case .image:
                    icon = UIImage(systemName: "photo")
                case .video:
                    icon = UIImage(systemName: "video")
                case .audio:
                    icon = UIImage(systemName: "mic")
                }
                
                thumbnailView.image = icon
                thumbnailView.tintColor = .systemGray
                
                attachmentsView.addArrangedSubview(thumbnailView)
                
                // Set fixed size for thumbnails
                NSLayoutConstraint.activate([
                    thumbnailView.widthAnchor.constraint(equalToConstant: 44),
                    thumbnailView.heightAnchor.constraint(equalToConstant: 44)
                ])
            }
        }
        
        // Show or hide attachments view
        attachmentsView.isHidden = note.attachments.isEmpty
        
        // Configure location label
        locationLabel.text = "📍 Location"
        locationLabel.isHidden = note.location == nil
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        contentLabel.text = nil
        dateLabel.text = nil
        locationLabel.text = nil
        locationLabel.isHidden = true
        
        attachmentsView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        attachmentsView.isHidden = true
    }
}

// MARK: - AddNoteViewController
class AddNoteViewController: UIViewController, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Properties
    private let scrollView = UIScrollView()
    private let containerView = UIView()
    
    private let titleTextField = UITextField()
    private let contentTextView = UITextView()
    private let attachmentsCollectionView: UICollectionView!
    private let locationSwitch = UISwitch()
    
    private let projectId: String
    private var editingNote: Note?
    private var attachments: [Attachment] = []
    private var mediaItems: [MediaItem] = []
    
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocationCoordinate2D?
    
    // MARK: - Initializers
    init(projectId: String, editingNote: Note? = nil) {
        self.projectId = projectId
        self.editingNote = editingNote
        
        // Initialize collection view with flow layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 80, height: 80)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        attachmentsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        setupNavigationBar()
        setupLocationManager()
        populateExistingData()
    }
    
    // MARK: - Setup Methods
    private func setupViews() {
        view.backgroundColor = .systemBackground
        title = editingNote != nil ? "Edit Note" : "Add Note"
        
        // Scroll View setup
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(containerView)
        
        // Title TextField setup
        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        titleTextField.placeholder = "Title (Optional)"
        titleTextField.borderStyle = .roundedRect
        titleTextField.font = UIFont.systemFont(ofSize: 17)
        containerView.addSubview(titleTextField)
        
        // Content TextView setup
        contentTextView.translatesAutoresizingMaskIntoConstraints = false
        contentTextView.font = UIFont.systemFont(ofSize: 17)
        contentTextView.layer.borderColor = UIColor.systemGray4.cgColor
        contentTextView.layer.borderWidth = 0.5
        contentTextView.layer.cornerRadius = 5
        contentTextView.text = "Note Content"
        contentTextView.textColor = .placeholderText
        contentTextView.delegate = self
        containerView.addSubview(contentTextView)
        
        // Attachments Collection View setup
        attachmentsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        attachmentsCollectionView.backgroundColor = .clear
        attachmentsCollectionView.delegate = self
        attachmentsCollectionView.dataSource = self
        attachmentsCollectionView.register(MediaCell.self, forCellWithReuseIdentifier: "MediaCell")
        attachmentsCollectionView.register(AddMediaCell.self, forCellWithReuseIdentifier: "AddMediaCell")
        containerView.addSubview(attachmentsCollectionView)
        
        // Location Switch setup
        let locationView = UIView()
        locationView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(locationView)
        
        let locationLabel = UILabel()
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        locationLabel.text = "Include Current Location"
        locationLabel.font = UIFont.systemFont(ofSize: 17)
        locationView.addSubview(locationLabel)
        
        locationSwitch.translatesAutoresizingMaskIntoConstraints = false
        locationSwitch.isOn = false
        locationView.addSubview(locationSwitch)
        
        NSLayoutConstraint.activate([
            locationLabel.leadingAnchor.constraint(equalTo: locationView.leadingAnchor),
            locationLabel.centerYAnchor.constraint(equalTo: locationView.centerYAnchor),
            
            locationSwitch.trailingAnchor.constraint(equalTo: locationView.trailingAnchor),
            locationSwitch.centerYAnchor.constraint(equalTo: locationView.centerYAnchor),
            
            locationView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            titleTextField.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            contentTextView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 16),
            contentTextView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            contentTextView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            contentTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 150),
            
            attachmentsCollectionView.topAnchor.constraint(equalTo: contentTextView.bottomAnchor, constant: 16),
            attachmentsCollectionView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            attachmentsCollectionView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            attachmentsCollectionView.heightAnchor.constraint(equalToConstant: 100),
            
            containerView.subviews.last!.topAnchor.constraint(equalTo: attachmentsCollectionView.bottomAnchor, constant: 16),
            containerView.subviews.last!.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            containerView.subviews.last!.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            containerView.subviews.last!.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveTapped)
        )
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func populateExistingData() {
        guard let note = editingNote else { return }
        
        titleTextField.text = note.title
        
        if note.content.isEmpty {
            contentTextView.text = "Note Content"
            contentTextView.textColor = .placeholderText
        } else {
            contentTextView.text = note.content
            contentTextView.textColor = .label
        }
        
        locationSwitch.isOn = note.location != nil
        attachments = note.attachments
        
        // We'd ideally load media items here, but for the demo we'll just use placeholder icons
        for attachment in note.attachments {
            let mediaItem = MediaItem(
                type: attachment.type,
                data: nil,
                url: attachment.fileURL,
                thumbnail: nil
            )
            mediaItems.append(mediaItem)
        }
        
        attachmentsCollectionView.reloadData()
    }
    
    // MARK: - Action Methods
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        guard let content = contentTextView.text, contentTextView.textColor != .placeholderText, !content.isEmpty else {
            showAlert(message: "Please enter note content")
            return
        }
        
        // Get current location if switch is on
        var location: CLLocationCoordinate2D? = nil
        if locationSwitch.isOn {
            location = currentLocation
            
            if location == nil {
                // Start updating location and try again after a short delay
                locationManager.startUpdatingLocation()
                showAlert(message: "Getting your location. Please try again in a moment.")
                return
            }
        }
        
        // Check if we're editing or creating a new note
        if let editingNote = editingNote {
            updateExistingNote(editingNote, content: content, location: location)
        } else {
            createNewNote(content: content, location: location)
        }
    }
    
    private func createNewNote(content: String, location: CLLocationCoordinate2D?) {
        // First, upload any new media items
        uploadMediaItems { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let attachments):
                // Create the note with uploaded attachments
                let newNote = Note(
                    title: self.titleTextField.text,
                    content: content,
                    attachments: attachments,
                    location: location,
                    projectId: self.projectId
                )
                
                // Save the note
                FirebaseManager.shared.addNote(newNote) { [weak self] result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success:
                            self?.dismiss(animated: true)
                        case .failure(let error):
                            self?.showAlert(message: "Failed to save note: \(error.localizedDescription)")
                        }
                    }
                }
                
            case .failure(let error):
                self.showAlert(message: "Failed to upload attachments: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateExistingNote(_ note: Note, content: String, location: CLLocationCoordinate2D?) {
        // First, upload any new media items
        uploadMediaItems { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let newAttachments):
                // Create updated note with existing and new attachments
                var updatedNote = note
                updatedNote.title = self.titleTextField.text
                updatedNote.content = content
                updatedNote.location = location
                updatedNote.updatedAt = Date()
                
                // Combine existing attachments with new ones, respecting the 4 attachment limit
                let existingAttachments = self.editingNote?.attachments ?? []
                let combinedAttachments = existingAttachments + newAttachments
                updatedNote.attachments = Array(combinedAttachments.prefix(4))
                
                // Save the note
                FirebaseManager.shared.updateNote(updatedNote) { [weak self] result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success:
                            self?.dismiss(animated: true)
                        case .failure(let error):
                            self?.showAlert(message: "Failed to update note: \(error.localizedDescription)")
                        }
                    }
                }
                
            case .failure(let error):
                self.showAlert(message: "Failed to upload attachments: \(error.localizedDescription)")
            }
        }
    }
    
    private func uploadMediaItems(completion: @escaping (Result<[Attachment], Error>) -> Void) {
        // Filter out media items that already have a URL (they're already uploaded)
        let mediaItemsToUpload = mediaItems.filter { $0.url == nil }
        
        if mediaItemsToUpload.isEmpty {
            // No new media items to upload
            completion(.success([]))
            return
        }
        
        var uploadedAttachments: [Attachment] = []
        var uploadErrors: [Error] = []
        let uploadGroup = DispatchGroup()
        
        for mediaItem in mediaItemsToUpload {
            guard let data = mediaItem.data else { continue }
            
            uploadGroup.enter()
            
            FirebaseManager.shared.uploadMedia(data: data, type: mediaItem.type) { result in
                switch result {
                case .success(let urls):
                    let attachment = Attachment(
                        type: mediaItem.type,
                        fileURL: urls.fileURL,
                        thumbnailURL: urls.thumbnailURL
                    )
                    uploadedAttachments.append(attachment)
                case .failure(let error):
                    uploadErrors.append(error)
                }
                
                uploadGroup.leave()
            }
        }
        
        uploadGroup.notify(queue: .main) {
            if !uploadErrors.isEmpty {
                // Return the first error if any
                completion(.failure(uploadErrors[0]))
            } else {
                // Return the uploaded attachments
                completion(.success(uploadedAttachments))
            }
        }
    }
    
    private func showAttachmentOptions() {
        let alertController = UIAlertController(title: "Add Attachment", message: nil, preferredStyle: .actionSheet)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        // Take Photo
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alertController.addAction(UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
                self?.showImagePicker(sourceType: .camera, mediaTypes: ["public.image"])
            })
            
            alertController.addAction(UIAlertAction(title: "Record Video", style: .default) { [weak self] _ in
                self?.showImagePicker(sourceType: .camera, mediaTypes: ["public.movie"])
            })
        }
        
        // Choose from Library
        alertController.addAction(UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
            self?.showImagePicker(sourceType: .photoLibrary, mediaTypes: ["public.image", "public.movie"])
        })
        
        // Record Audio
        alertController.addAction(UIAlertAction(title: "Record Audio", style: .default) { [weak self] _ in
            self?.recordAudio()
        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alertController, animated: true)
    }
    
    private func showImagePicker(sourceType: UIImagePickerController.SourceType, mediaTypes: [String]) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = sourceType
        imagePicker.mediaTypes = mediaTypes
        present(imagePicker, animated: true)
    }
    
    private func recordAudio() {
        // In a real app, we would implement audio recording functionality
        // For this prototype, we'll just simulate adding an audio recording
        let audioData = Data(repeating: 0, count: 1000) // Dummy data
        
        let audioItem = MediaItem(
            type: .audio,
            data: audioData,
            url: nil,
            thumbnail: nil
        )
        
        addMediaItem(audioItem)
    }
    
    private func addMediaItem(_ mediaItem: MediaItem) {
        // Check if we already have 4 attachments
        if mediaItems.count >= 4 {
            showAlert(message: "Maximum of 4 attachments allowed")
            return
        }
        
        mediaItems.append(mediaItem)
        attachmentsCollectionView.reloadData()
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - UITextViewDelegate
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = ""
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Note Content"
            textView.textColor = .placeholderText
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        // Determine if image or video was picked
        if let image = info[.originalImage] as? UIImage, let imageData = image.jpegData(compressionQuality: 0.7) {
            // Image selected
            let mediaItem = MediaItem(
                type: .image,
                data: imageData,
                url: nil,
                thumbnail: image
            )
            addMediaItem(mediaItem)
        } else if let videoURL = info[.mediaURL] as? URL {
            // Video selected
            do {
                let videoData = try Data(contentsOf: videoURL)
                let mediaItem = MediaItem(
                    type: .video,
                    data: videoData,
                    url: nil,
                    thumbnail: nil
                )
                addMediaItem(mediaItem)
            } catch {
                showAlert(message: "Failed to process video: \(error.localizedDescription)")
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension AddNoteViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Show all media items plus one cell for the "add" button if we have fewer than 4 items
        return mediaItems.count < 4 ? mediaItems.count + 1 : mediaItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == mediaItems.count {
            // This is the "add" cell
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddMediaCell", for: indexPath) as? AddMediaCell else {
                return UICollectionViewCell()
            }
            return cell
        } else {
            // This is a media item cell
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MediaCell", for: indexPath) as? MediaCell else {
                return UICollectionViewCell()
            }
            
            let mediaItem = mediaItems[indexPath.item]
            cell.configure(with: mediaItem)
            cell.onDelete = { [weak self] in
                self?.mediaItems.remove(at: indexPath.item)
                self?.attachmentsCollectionView.reloadData()
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == mediaItems.count {
            // "Add" cell tapped
            showAttachmentOptions()
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension AddNoteViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location.coordinate
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
}

// MARK: - MediaItem
struct MediaItem {
    let type: Attachment.AttachmentType
    let data: Data?
    let url: String?
    let thumbnail: UIImage?
}

// MARK: - MediaCell
class MediaCell: UICollectionViewCell {
    
    // MARK: - Properties
    private let imageView = UIImageView()
    private let deleteButton = UIButton(type: .system)
    var onDelete: (() -> Void)?
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    private func setupViews() {
        // Image View setup
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray6
        contentView.addSubview(imageView)
        
        // Delete Button setup
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.backgroundColor = .white
        deleteButton.layer.cornerRadius = 10
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        contentView.addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            deleteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: -8),
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 8),
            deleteButton.widthAnchor.constraint(equalToConstant: 24),
            deleteButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    // MARK: - Action Methods
    @objc private func deleteButtonTapped() {
        onDelete?()
    }
    
    // MARK: - Configuration
    func configure(with mediaItem: MediaItem) {
        // Set thumbnail or icon
        if let thumbnail = mediaItem.thumbnail {
            imageView.image = thumbnail
            imageView.contentMode = .scaleAspectFill
        } else {
            // Show icon based on media type
            let icon: UIImage?
            switch mediaItem.type {
            case .image:
                icon = UIImage(systemName: "photo")
            case .video:
                icon = UIImage(systemName: "video")
            case .audio:
                icon = UIImage(systemName: "mic")
            }
            
            imageView.image = icon
            imageView.contentMode = .center
            imageView.tintColor = .systemGray
        }
    }
}

// MARK: - AddMediaCell
class AddMediaCell: UICollectionViewCell {
    
    // MARK: - Properties
    private let plusButton = UIButton(type: .system)
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    private func setupViews() {
        contentView.backgroundColor = .systemGray6
        contentView.layer.cornerRadius = 8
        
        plusButton.translatesAutoresizingMaskIntoConstraints = false
        plusButton.setImage(UIImage(systemName: "plus"), for: .normal)
        plusButton.tintColor = .systemBlue
        contentView.addSubview(plusButton)
        
        NSLayoutConstraint.activate([
            plusButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            plusButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            plusButton.widthAnchor.constraint(equalToConstant: 30),
            plusButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
}

// MARK: - ViewNoteViewController
class ViewNoteViewController: UIViewController {
    
    // MARK: - Properties
    private let note: Note
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // MARK: - Initializers
    init(note: Note) {
        self.note = note
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    // MARK: - Setup Methods
    private func setupViews() {
        view.backgroundColor = .systemBackground
        title = note.title ?? "Note"
        
        // Setup navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Add components
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        
        // Add note content
        let contentLabel = UILabel()
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.text = note.content
        contentLabel.numberOfLines = 0
        contentLabel.font = UIFont.systemFont(ofSize: 17)
        stackView.addArrangedSubview(contentLabel)
        
        // Add attachments if any
        if !note.attachments.isEmpty {
            let attachmentsLabel = UILabel()
            attachmentsLabel.translatesAutoresizingMaskIntoConstraints = false
            attachmentsLabel.text = "Attachments"
            attachmentsLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
            stackView.addArrangedSubview(attachmentsLabel)
            
            let attachmentsStackView = UIStackView()
            attachmentsStackView.translatesAutoresizingMaskIntoConstraints = false
            attachmentsStackView.axis = .vertical
            attachmentsStackView.spacing = 8
            stackView.addArrangedSubview(attachmentsStackView)
            
            for attachment in note.attachments {
                let attachmentView = createAttachmentView(for: attachment)
                attachmentsStackView.addArrangedSubview(attachmentView)
            }
        }
        
        // Add location if available
        if let location = note.location {
            let locationLabel = UILabel()
            locationLabel.translatesAutoresizingMaskIntoConstraints = false
            locationLabel.text = "📍 Location: \(location.latitude), \(location.longitude)"
            locationLabel.numberOfLines = 0
            locationLabel.font = UIFont.systemFont(ofSize: 14)
            locationLabel.textColor = .secondaryLabel
            stackView.addArrangedSubview(locationLabel)
        }
        
        // Add timestamps
        let createdLabel = UILabel()
        createdLabel.translatesAutoresizingMaskIntoConstraints = false
        let createdDate = DateFormatter.localizedString(from: note.createdAt, dateStyle: .medium, timeStyle: .short)
        createdLabel.text = "Created: \(createdDate)"
        createdLabel.font = UIFont.systemFont(ofSize: 14)
        createdLabel.textColor = .secondaryLabel
        stackView.addArrangedSubview(createdLabel)
        
        let updatedLabel = UILabel()
        updatedLabel.translatesAutoresizingMaskIntoConstraints = false
        let updatedDate = DateFormatter.localizedString(from: note.updatedAt, dateStyle: .medium, timeStyle: .short)
        updatedLabel.text = "Last Updated: \(updatedDate)"
        updatedLabel.font = UIFont.systemFont(ofSize: 14)
        updatedLabel.textColor = .secondaryLabel
        stackView.addArrangedSubview(updatedLabel)
    }
    
    private func createAttachmentView(for attachment: Attachment) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 8
        
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .systemBlue
        
        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont.systemFont(ofSize: 15)
        
        // Configure based on attachment type
        switch attachment.type {
        case .image:
            iconView.image = UIImage(systemName: "photo")
            nameLabel.text = "Image"
        case .video:
            iconView.image = UIImage(systemName: "video")
            nameLabel.text = "Video"
        case .audio:
            iconView.image = UIImage(systemName: "mic")
            nameLabel.text = "Audio Recording"
        }
        
        containerView.addSubview(iconView)
        containerView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: 60),
            
            iconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 16),
            nameLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
        
        // Add tap gesture to view attachment
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(attachmentTapped(_:)))
        containerView.addGestureRecognizer(tapGesture)
        containerView.isUserInteractionEnabled = true
        containerView.tag = attachment.id.hashValue // Use hash to identify attachment
        
        return containerView
    }
    
    @objc private func attachmentTapped(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view else { return }
        
        // Find attachment based on view tag
        let attachmentHash = view.tag
        guard let attachment = note.attachments.first(where: { $0.id.hashValue == attachmentHash }) else { return }
        
        // In a real app, we would open the attachment
        let alert = UIAlertController(title: "Attachment", message: "Would open \(attachment.fileURL)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}
