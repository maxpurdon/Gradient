//
//  AddTaskViewController.swift
//  Gradient
//
//  Created by Andrew Purdon on 07/03/2025.
//
import UIKit
import SwiftUI
import Foundation
import UserNotifications
class AddTaskViewController: UIViewController {
    // MARK: - Properties
    private let task: Task?
    private let projectId: String
    private let titleTextField = UITextField()
    private let dueDatePicker = UIDatePicker()
    private let notifySwitch = UISwitch()
    
    // MARK: - Initializers
    init(task: Task? = nil) {
        self.task = task
        self.projectId = task?.projectId ?? ""
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
        
        if let task = task {
            populateTaskData(task)
        }
    }
    
    // MARK: - Setup Methods
    private func setupViews() {
        view.backgroundColor = .systemBackground
        title = task == nil ? "Add Task" : "Edit Task"
        
        // Title TextField
        titleTextField.placeholder = "Task Title"
        titleTextField.borderStyle = .roundedRect
        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleTextField)
        
        // Due Date Picker
        dueDatePicker.datePickerMode = .dateAndTime
        dueDatePicker.minimumDate = Date()
        dueDatePicker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dueDatePicker)
        
        // Notify Switch
        let notifyView = UIView()
        notifyView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(notifyView)
        
        let notifyLabel = UILabel()
        notifyLabel.text = "Notify"
        notifyLabel.translatesAutoresizingMaskIntoConstraints = false
        notifyView.addSubview(notifyLabel)
        
        notifySwitch.translatesAutoresizingMaskIntoConstraints = false
        notifyView.addSubview(notifySwitch)
        
        NSLayoutConstraint.activate([
            notifyLabel.leadingAnchor.constraint(equalTo: notifyView.leadingAnchor),
            notifyLabel.centerYAnchor.constraint(equalTo: notifyView.centerYAnchor),
            
            notifySwitch.trailingAnchor.constraint(equalTo: notifyView.trailingAnchor),
            notifySwitch.centerYAnchor.constraint(equalTo: notifyView.centerYAnchor)
        ])
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            dueDatePicker.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 16),
            dueDatePicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            view.subviews.last!.topAnchor.constraint(equalTo: dueDatePicker.bottomAnchor, constant: 16),
            view.subviews.last!.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            view.subviews.last!.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            view.subviews.last!.heightAnchor.constraint(equalToConstant: 44)
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
    
    private func populateTaskData(_ task: Task) {
        titleTextField.text = task.title
        
        if let dueDate = task.dueDate {
            dueDatePicker.date = dueDate
        }
        
        notifySwitch.isOn = task.notifyUser
    }
    
    // MARK: - Action Methods
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        guard let title = titleTextField.text, !title.isEmpty else {
            showAlert(message: "Please enter a task title")
            return
        }
        
        if let task = task {
            // Update existing task
            var updatedTask = task
            updatedTask.title = title
            updatedTask.dueDate = dueDatePicker.date
            updatedTask.notifyUser = notifySwitch.isOn
            updatedTask.notificationDate = notifySwitch.isOn ? dueDatePicker.date : nil
            updatedTask.updatedAt = Date()
            
            FirebaseManager.shared.updateTask(updatedTask) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        if updatedTask.notifyUser {
                            NotificationManager.shared.scheduleNotification(
                                for: updatedTask.id,
                                title: "Task Reminder",
                                body: "Task: \(updatedTask.title)",
                                date: self.dueDatePicker.date
                            )
                        } else {
                            NotificationManager.shared.cancelNotification(for: updatedTask.id)
                        }
                        self.dismiss(animated: true)
                    case .failure(let error):
                        self.showAlert(message: "Failed to update task: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            // Create new task
            let newTask = Task(
                title: title,
                status: .notStarted,
                dueDate: dueDatePicker.date,
                notifyUser: notifySwitch.isOn,
                notificationDate: notifySwitch.isOn ? dueDatePicker.date : nil,
                projectId: projectId
            )
            
            FirebaseManager.shared.addTask(newTask) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        if newTask.notifyUser {
                            NotificationManager.shared.scheduleNotification(
                                for: newTask.id,
                                title: "Task Reminder",
                                body: "Task: \(newTask.title)",
                                date: self.dueDatePicker.date
                            )
                        }
                        self.dismiss(animated: true)
                    case .failure(let error):
                        self.showAlert(message: "Failed to create task: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
