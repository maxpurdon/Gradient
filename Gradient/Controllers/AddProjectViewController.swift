//
//  AddProjectViewController.swift
//  Gradient
//
//  Created by Andrew Purdon on 06/03/2025.
//


import UIKit

class AddProjectViewController: UIViewController {
    
    // MARK: - Properties
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let titleTextField = UITextField()
    private let descriptionTextView = UITextView()
    
    private let workshopsLabel = UILabel()
    private let workshopsTagView = TagView()
    private let workshopsTextField = UITextField()
    
    private let materialsNeededLabel = UILabel()
    private let materialsNeededTagView = TagView()
    private let materialsNeededTextField = UITextField()
    
    private let materialsFoundLabel = UILabel()
    private let materialsFoundTagView = TagView()
    private let materialsFoundTextField = UITextField()
    
    private let statusLabel = UILabel()
    private let statusSegmentedControl = UISegmentedControl()
    
    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    
    private var editingProject: Project?
    
    // MARK: - Initializers
    init(project: Project? = nil) {
        self.editingProject = project
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
        setupActions()
        populateExistingData()
    }
    
    // MARK: - Setup Methods
    private func setupViews() {
        view.backgroundColor = .systemBackground
        
        // Scroll View setup
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Title setup
        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        titleTextField.placeholder = "Project Title *"
        titleTextField.borderStyle = .roundedRect
        titleTextField.font = UIFont.systemFont(ofSize: 17)
        contentView.addSubview(titleTextField)
        
        // Description setup
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        descriptionTextView.font = UIFont.systemFont(ofSize: 17)
        descriptionTextView.layer.borderColor = UIColor.systemGray4.cgColor
        descriptionTextView.layer.borderWidth = 0.5
        descriptionTextView.layer.cornerRadius = 5
        descriptionTextView.text = "Project Description"
        descriptionTextView.textColor = .placeholderText
        descriptionTextView.delegate = self
        contentView.addSubview(descriptionTextView)
        
        // Workshops setup
        workshopsLabel.translatesAutoresizingMaskIntoConstraints = false
        workshopsLabel.text = "Workshops"
        workshopsLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        contentView.addSubview(workshopsLabel)
        
        workshopsTagView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(workshopsTagView)
        
        workshopsTextField.translatesAutoresizingMaskIntoConstraints = false
        workshopsTextField.placeholder = "Add workshop (press return)"
        workshopsTextField.borderStyle = .roundedRect
        workshopsTextField.font = UIFont.systemFont(ofSize: 17)
        workshopsTextField.delegate = self
        contentView.addSubview(workshopsTextField)
        
        // Materials Needed setup
        materialsNeededLabel.translatesAutoresizingMaskIntoConstraints = false
        materialsNeededLabel.text = "Materials Needed"
        materialsNeededLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        contentView.addSubview(materialsNeededLabel)
        
        materialsNeededTagView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(materialsNeededTagView)
        
        materialsNeededTextField.translatesAutoresizingMaskIntoConstraints = false
        materialsNeededTextField.placeholder = "Add material needed (press return)"
        materialsNeededTextField.borderStyle = .roundedRect
        materialsNeededTextField.font = UIFont.systemFont(ofSize: 17)
        materialsNeededTextField.delegate = self
        contentView.addSubview(materialsNeededTextField)
        
        // Materials Found setup
        materialsFoundLabel.translatesAutoresizingMaskIntoConstraints = false
        materialsFoundLabel.text = "Materials Found"
        materialsFoundLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        contentView.addSubview(materialsFoundLabel)
        
        materialsFoundTagView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(materialsFoundTagView)
        
        materialsFoundTextField.translatesAutoresizingMaskIntoConstraints = false
        materialsFoundTextField.placeholder = "Add material found (press return)"
        materialsFoundTextField.borderStyle = .roundedRect
        materialsFoundTextField.font = UIFont.systemFont(ofSize: 17)
        materialsFoundTextField.delegate = self
        contentView.addSubview(materialsFoundTextField)
        
        // Status setup
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "Status"
        statusLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        contentView.addSubview(statusLabel)
        
        let statusItems = Project.Status.allCases.map { $0.rawValue }
        statusSegmentedControl = UISegmentedControl(items: statusItems)
        statusSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        statusSegmentedControl.selectedSegmentIndex = 0
        contentView.addSubview(statusSegmentedControl)
        
        // Buttons setup
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.setTitle(editingProject != nil ? "Update Project" : "Create Project", for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        saveButton.backgroundColor = .systemBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 10
        contentView.addSubview(saveButton)
        
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        cancelButton.setTitleColor(.systemRed, for: .normal)
        contentView.addSubview(cancelButton)
    }
    
    private func setupConstraints() {
        let padding: CGFloat = 20
        
        NSLayoutConstraint.activate([
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title TextField
            titleTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            titleTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            titleTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            // Description Text View
            descriptionTextView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: padding),
            descriptionTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            descriptionTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            descriptionTextView.heightAnchor.constraint(equalToConstant: 100),
            
            // Workshops
            workshopsLabel.topAnchor.constraint(equalTo: descriptionTextView.bottomAnchor, constant: padding),
            workshopsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            workshopsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            workshopsTagView.topAnchor.constraint(equalTo: workshopsLabel.bottomAnchor, constant: 10),
            workshopsTagView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            workshopsTagView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            workshopsTextField.topAnchor.constraint(equalTo: workshopsTagView.bottomAnchor, constant: 10),
            workshopsTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            workshopsTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            // Materials Needed
            materialsNeededLabel.topAnchor.constraint(equalTo: workshopsTextField.bottomAnchor, constant: padding),
            materialsNeededLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            materialsNeededLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            materialsNeededTagView.topAnchor.constraint(equalTo: materialsNeededLabel.bottomAnchor, constant: 10),
            materialsNeededTagView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            materialsNeededTagView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            materialsNeededTextField.topAnchor.constraint(equalTo: materialsNeededTagView.bottomAnchor, constant: 10),
            materialsNeededTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            materialsNeededTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            // Materials Found
            materialsFoundLabel.topAnchor.constraint(equalTo: materialsNeededTextField.bottomAnchor, constant: padding),
            materialsFoundLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            materialsFoundLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            materialsFoundTagView.topAnchor.constraint(equalTo: materialsFoundLabel.bottomAnchor, constant: 10),
            materialsFoundTagView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            materialsFoundTagView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            materialsFoundTextField.topAnchor.constraint(equalTo: materialsFoundTagView.bottomAnchor, constant: 10),
            materialsFoundTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            materialsFoundTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            // Status
            statusLabel.topAnchor.constraint(equalTo: materialsFoundTextField.bottomAnchor, constant: padding),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            statusSegmentedControl.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 10),
            statusSegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            statusSegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            // Buttons
            saveButton.topAnchor.constraint(equalTo: statusSegmentedControl.bottomAnchor, constant: padding * 1.5),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            
            cancelButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 10),
            cancelButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            cancelButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
            cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding)
        ])
    }
    
    private func setupActions() {
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        
        workshopsTagView.onTagRemoved = { [weak self] tag in
            self?.workshopsTagView.removeTag(tag)
        }
        
        materialsNeededTagView.onTagRemoved = { [weak self] tag in
            self?.materialsNeededTagView.removeTag(tag)
        }
        
        materialsFoundTagView.onTagRemoved = { [weak self] tag in
            self?.materialsFoundTagView.removeTag(tag)
        }
    }
    
    private func populateExistingData() {
        guard let project = editingProject else { return }
        
        titleTextField.text = project.name
        
        if project.description.isEmpty {
            descriptionTextView.text = "Project Description"
            descriptionTextView.textColor = .placeholderText
        } else {
            descriptionTextView.text = project.description
            descriptionTextView.textColor = .label
        }
        
        // Add tags
        for workshop in project.workshops {
            workshopsTagView.addTag(workshop)
        }
        
        for material in project.materialsNeeded {
            materialsNeededTagView.addTag(material)
        }
        
        for material in project.materialsFound {
            materialsFoundTagView.addTag(material)
        }
        
        // Set status
        if let index = Project.Status.allCases.firstIndex(where: { $0 == project.status }) {
            statusSegmentedControl.selectedSegmentIndex = index
        }
    }
    
    // MARK: - Action Methods
    @objc private func saveButtonTapped() {
        guard let title = titleTextField.text, !title.isEmpty else {
            showAlert(message: "Please enter a project title")
            return
        }
        
        let description = descriptionTextView.textColor == .placeholderText ? "" : descriptionTextView.text
        
        let selectedStatusIndex = statusSegmentedControl.selectedSegmentIndex
        let status = Project.Status.allCases[selectedStatusIndex]
        
        if let editingProject = editingProject {
            // Update existing project
            var updatedProject = editingProject
            updatedProject.name = title
            updatedProject.description = description ?? ""
            updatedProject.status = status
            updatedProject.workshops = workshopsTagView.tags
            updatedProject.materialsNeeded = materialsNeededTagView.tags
            updatedProject.materialsFound = materialsFoundTagView.tags
            updatedProject.updatedAt = Date()
            
            FirebaseManager.shared.updateProject(updatedProject) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self.dismiss(animated: true)
                    case .failure(let error):
                        self.showAlert(message: "Failed to update project: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            // Create new project
            let newProject = Project(
                name: title,
                description: description ?? "",
                status: status,
                workshops: workshopsTagView.tags,
                materialsNeeded: materialsNeededTagView.tags,
                materialsFound: materialsFoundTagView.tags
            )
            
            FirebaseManager.shared.addProject(newProject) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self.dismiss(animated: true)
                    case .failure(let error):
                        self.showAlert(message: "Failed to create project: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension AddProjectViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == workshopsTextField, let text = textField.text, !text.isEmpty {
            workshopsTagView.addTag(text)
            textField.text = ""
        } else if textField == materialsNeededTextField, let text = textField.text, !text.isEmpty {
            materialsNeededTagView.addTag(text)
            textField.text = ""
        } else if textField == materialsFoundTextField, let text = textField.text, !text.isEmpty {
            materialsFoundTagView.addTag(text)
            textField.text = ""
        }
        
        return true
    }
}

// MARK: - UITextViewDelegate
extension AddProjectViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = ""
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Project Description"
            textView.textColor = .placeholderText
        }
    }
}

// MARK: - TagView
class TagView: UIView {
    
    // MARK: - Properties
    private let stackView = UIStackView()
    private let scrollView = UIScrollView()
    
    var tags: [String] = []
    var onTagRemoved: ((String) -> Void)?
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    private func setupView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .leading
        stackView.distribution = .fillProportionally
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        scrollView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 40),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }
    
    // MARK: - Public Methods
    func addTag(_ tag: String) {
        guard !tags.contains(tag) else { return }
        
        tags.append(tag)
        
        let tagView = createTagView(tag)
        stackView.addArrangedSubview(tagView)
        
        layoutIfNeeded()
        scrollView.contentSize = stackView.frame.size
    }
    
    func removeTag(_ tag: String) {
        guard let index = tags.firstIndex(of: tag) else { return }
        
        tags.remove(at: index)
        
        for subview in stackView.arrangedSubviews {
            if let tagView = subview as? UIView,
               let label = tagView.subviews.first(where: { $0 is UILabel }) as? UILabel,
               label.text == tag {
                tagView.removeFromSuperview()
                break
            }
        }
        
        layoutIfNeeded()
        scrollView.contentSize = stackView.frame.size
    }
    
    // MARK: - Private Methods
    private func createTagView(_ tag: String) -> UIView {
        let tagView = UIView()
        tagView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        tagView.layer.cornerRadius = 15
        tagView.layer.borderWidth = 1
        tagView.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.2).cgColor
        
        let label = UILabel()
        label.text = tag
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let removeButton = UIButton(type: .system)
        removeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        removeButton.tintColor = .systemBlue
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.addTarget(self, action: #selector(removeTagButtonTapped(_:)), for: .touchUpInside)
        
        tagView.addSubview(label)
        tagView.addSubview(removeButton)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: tagView.topAnchor, constant: 5),
            label.leadingAnchor.constraint(equalTo: tagView.leadingAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: tagView.bottomAnchor, constant: -5),
            
            removeButton.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            removeButton.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 5),
            removeButton.trailingAnchor.constraint(equalTo: tagView.trailingAnchor, constant: -5),
            removeButton.widthAnchor.constraint(equalToConstant: 20),
            removeButton.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        return tagView
    }
    
    @objc private func removeTagButtonTapped(_ sender: UIButton) {
        guard let tagView = sender.superview else { return }
        
        if let label = tagView.subviews.first(where: { $0 is UILabel }) as? UILabel, let tag = label.text {
            onTagRemoved?(tag)
        }
    }
}