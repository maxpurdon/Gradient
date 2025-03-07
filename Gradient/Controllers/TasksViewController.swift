//
//  TasksViewController.swift
//  Gradient
//
//  Created by Andrew Purdon on 06/03/2025.
//


import UIKit
import UserNotifications

class TasksViewController: UIViewController {
    
    // MARK: - Properties
    private let tableView = UITableView()
    private let addTaskView = SimpleTaskInputView()
    
    private let projectId: String
    private var tasks: [Task] = []
    
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
        observeTasks()
    }
    
    // MARK: - Setup Methods
    private func setupViews() {
        view.backgroundColor = .systemBackground
        
        // Table View
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TaskCell.self, forCellReuseIdentifier: "TaskCell")
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)
        
        // Add Task View
        addTaskView.translatesAutoresizingMaskIntoConstraints = false
        addTaskView.delegate = self
        view.addSubview(addTaskView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            addTaskView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            addTaskView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            addTaskView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: addTaskView.topAnchor)
        ])
    }
    
    // MARK: - Data Methods
    private func observeTasks() {
        FirebaseManager.shared.observeTasks(forProject: projectId) { [weak self] tasks in
            guard let self = self else { return }
            
            self.tasks = tasks.sorted { 
                // Sort by completion status (incomplete first), then by due date (earliest first)
                if $0.status != .completed && $1.status == .completed {
                    return true
                } else if $0.status == .completed && $1.status != .completed {
                    return false
                } else if let date0 = $0.dueDate, let date1 = $1.dueDate {
                    return date0 < date1
                } else if $0.dueDate != nil && $1.dueDate == nil {
                    return true
                } else if $0.dueDate == nil && $1.dueDate != nil {
                    return false
                } else {
                    return $0.createdAt > $1.createdAt
                }
            }
            
            self.tableView.reloadData()
        }
    }
    
    // MARK: - Helper Methods
    private func showTaskOptions(for task: Task, sender: UIView) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }
        
        // Edit option
        alertController.addAction(UIAlertAction(title: "Edit Task", style: .default) { [weak self] _ in
            self?.editTask(task)
        })
        
        // Toggle completion option
        let completionTitle = task.status == .completed ? "Mark as Incomplete" : "Mark as Complete"
        alertController.addAction(UIAlertAction(title: completionTitle, style: .default) { [weak self] _ in
            self?.toggleTaskCompletion(task)
        })
        
        // Set reminder option
        if task.status != .completed {
            let reminderTitle = task.notifyUser ? "Remove Reminder" : "Set Reminder"
            alertController.addAction(UIAlertAction(title: reminderTitle, style: .default) { [weak self] _ in
                self?.toggleTaskReminder(task)
            })
        }
        
        // Delete option
        alertController.addAction(UIAlertAction(title: "Delete Task", style: .destructive) { [weak self] _ in
            self?.confirmDeleteTask(task)
        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alertController, animated: true)
    }
    
    private func editTask(_ task: Task) {
        let editTaskVC = AddTaskViewController(task: task)
        let navController = UINavigationController(rootViewController: editTaskVC)
        present(navController, animated: true)
    }
    
    private func toggleTaskCompletion(_ task: Task) {
        var updatedTask = task
        updatedTask.status = task.status == .completed ? .notStarted : .completed
        updatedTask.updatedAt = Date()
        
        FirebaseManager.shared.updateTask(updatedTask) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Tasks will be updated via the Firebase observer
                    
                    // Cancel notification if task is completed
                    if updatedTask.status == .completed && updatedTask.notifyUser {
                        NotificationManager.shared.cancelNotification(for: updatedTask.id)
                    }
                    
                case .failure(let error):
                    self.showAlert(message: "Failed to update task: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func toggleTaskReminder(_ task: Task) {
        if task.notifyUser {
            // Turn off notification
            var updatedTask = task
            updatedTask.notifyUser = false
            updatedTask.notificationDate = nil
            updatedTask.updatedAt = Date()
            
            FirebaseManager.shared.updateTask(updatedTask) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        NotificationManager.shared.cancelNotification(for: task.id)
                    case .failure(let error):
                        self.showAlert(message: "Failed to update task: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            // Show date picker to set notification
            showDatePicker(for: task)
        }
    }
    
    private func showDatePicker(for task: Task) {
        let alertController = UIAlertController(title: "Set Reminder", message: "\n\n\n\n\n\n", preferredStyle: .alert)
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.minimumDate = Date()
        if let dueDate = task.dueDate {
            datePicker.date = dueDate
        }
        
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        alertController.view.addSubview(datePicker)
        
        NSLayoutConstraint.activate([
            datePicker.topAnchor.constraint(equalTo: alertController.view.topAnchor, constant: 50),
            datePicker.leadingAnchor.constraint(equalTo: alertController.view.leadingAnchor, constant: 0),
            datePicker.trailingAnchor.constraint(equalTo: alertController.view.trailingAnchor, constant: 0),
        ])
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alertController.addAction(UIAlertAction(title: "Set Reminder", style: .default) { [weak self] _ in
            self?.scheduleReminder(for: task, at: datePicker.date)
        })
        
        present(alertController, animated: true)
    }
    
    private func scheduleReminder(for task: Task, at date: Date) {
        var updatedTask = task
        updatedTask.notifyUser = true
        updatedTask.notificationDate = date
        updatedTask.updatedAt = Date()
        
        FirebaseManager.shared.updateTask(updatedTask) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Schedule local notification
                    NotificationManager.shared.scheduleNotification(
                        for: updatedTask.id,
                        title: "Task Reminder",
                        body: "Task: \(updatedTask.title)",
                        date: date
                    )
                case .failure(let error):
                    self.showAlert(message: "Failed to set reminder: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func confirmDeleteTask(_ task: Task) {
        let alertController = UIAlertController(
            title: "Delete Task",
            message: "Are you sure you want to delete this task?",
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alertController.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteTask(task)
        })
        
        present(alertController, animated: true)
    }
    
    private func deleteTask(_ task: Task) {
        FirebaseManager.shared.deleteTask(task.id, fromProject: projectId) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Cancel any pending notifications
                    if task.notifyUser {
                        NotificationManager.shared.cancelNotification(for: task.id)
                    }
                case .failure(let error):
                    self.showAlert(message: "Failed to delete task: \(error.localizedDescription)")
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

// MARK: - UITableViewDelegate, UITableViewDataSource
extension TasksViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tasks.isEmpty {
            return 1 // For empty state cell
        }
        return tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tasks.isEmpty {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "EmptyCell")
            cell.textLabel?.text = "No tasks yet - add a task below"
            cell.textLabel?.textColor = .secondaryLabel
            cell.textLabel?.textAlignment = .center
            cell.selectionStyle = .none
            return cell
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell") as? TaskCell else {
            return UITableViewCell()
        }
        
        let task = tasks[indexPath.row]
        cell.configure(with: task)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if tasks.isEmpty {
            return
        }
        
        let task = tasks[indexPath.row]
        toggleTaskCompletion(task)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if tasks.isEmpty {
            return nil
        }
        
        let task = tasks[indexPath.row]
        
        // Delete action
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.confirmDeleteTask(task)
            completion(true)
        }
        deleteAction.backgroundColor = .systemRed
        
        // Complete/incomplete action
        let completeTitle = task.status == .completed ? "Incomplete" : "Complete"
        let completeAction = UIContextualAction(style: .normal, title: completeTitle) { [weak self] _, _, completion in
            self?.toggleTaskCompletion(task)
            completion(true)
        }
        completeAction.backgroundColor = task.status == .completed ? .systemOrange : .systemGreen
        
        return UISwipeActionsConfiguration(actions: [deleteAction, completeAction])
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tasks.isEmpty ? 100 : UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if tasks.isEmpty {
            return nil
        }
        
        let task = tasks[indexPath.row]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            // Create Edit action
            let editAction = UIAction(title: "Edit", image: UIImage(systemName: "pencil")) { [weak self] _ in
                self?.editTask(task)
            }
            
            // Create Complete/Incomplete action
            let completeTitle = task.status == .completed ? "Mark as Incomplete" : "Mark as Complete"
            let completeImage = task.status == .completed ? UIImage(systemName: "circle") : UIImage(systemName: "checkmark.circle")
            let completeAction = UIAction(title: completeTitle, image: completeImage) { [weak self] _ in
                self?.toggleTaskCompletion(task)
            }
            
            // Create Reminder action (if not completed)
            var reminderAction: UIAction?
            if task.status != .completed {
                let reminderTitle = task.notifyUser ? "Remove Reminder" : "Set Reminder"
                let reminderImage = task.notifyUser ? UIImage(systemName: "bell.slash") : UIImage(systemName: "bell")
                reminderAction = UIAction(title: reminderTitle, image: reminderImage) { [weak self] _ in
                    self?.toggleTaskReminder(task)
                }
            }
            
            // Create Delete action
            let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                self?.confirmDeleteTask(task)
            }
            
            // Combine actions into a menu
            var actions = [editAction, completeAction]
            if let reminderAction = reminderAction {
                actions.append(reminderAction)
            }
            actions.append(deleteAction)
            
            return UIMenu(title: "", children: actions)
        }
    }
}

// MARK: - SimpleTaskInputViewDelegate
extension TasksViewController: SimpleTaskInputViewDelegate {
    func simpleTaskInputViewDidSubmit(_ view: SimpleTaskInputView, taskTitle: String, dueDate: Date?, notify: Bool) {
        let task = Task(
            title: taskTitle,
            status: .notStarted,
            dueDate: dueDate,
            notifyUser: notify,
            notificationDate: notify ? dueDate : nil,
            projectId: projectId
        )
        
        FirebaseManager.shared.addTask(task) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Schedule notification if needed
                    if notify, let date = dueDate {
                        NotificationManager.shared.scheduleNotification(
                            for: task.id,
                            title: "Task Reminder",
                            body: "Task: \(task.title)",
                            date: date
                        )
                    }
                    
                    // Clear input
                    view.clearInput()
                    
                case .failure(let error):
                    self.showAlert(message: "Failed to add task: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - SimpleTaskInputView
protocol SimpleTaskInputViewDelegate: AnyObject {
    func simpleTaskInputViewDidSubmit(_ view: SimpleTaskInputView, taskTitle: String, dueDate: Date?, notify: Bool)
}

class SimpleTaskInputView: UIView {
    
    // MARK: - Properties
    private let textField = UITextField()
    private let addButton = UIButton(type: .system)
    private let dueDateButton = UIButton(type: .system)
    private let notifySwitch = UISwitch()
    
    private var dueDate: Date?
    private var notify: Bool = false
    
    weak var delegate: SimpleTaskInputViewDelegate?
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupConstraints()
    }
    
    // MARK: - Setup Methods
    private func setupViews() {
        backgroundColor = .systemBackground
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowRadius = 3
        layer.shadowOpacity = 0.1
        
        // Text Field
        textField.placeholder = "Add a new task..."
        textField.borderStyle = .roundedRect
        textField.returnKeyType = .done
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textField)
        
        // Due Date Button
        dueDateButton.setImage(UIImage(systemName: "calendar"), for: .normal)
        dueDateButton.addTarget(self, action: #selector(dueDateButtonTapped), for: .touchUpInside)
        dueDateButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dueDateButton)
        
        // Notification Switch
        notifySwitch.isOn = false
        notifySwitch.addTarget(self, action: #selector(notifySwitchChanged), for: .valueChanged)
        notifySwitch.translatesAutoresizingMaskIntoConstraints = false
        addSubview(notifySwitch)
        
        // Notification Label
        let notifyLabel = UILabel()
        notifyLabel.text = "Notify"
        notifyLabel.font = UIFont.systemFont(ofSize: 12)
        notifyLabel.textColor = .secondaryLabel
        notifyLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(notifyLabel)
        
        // Add Button
        addButton.setTitle("Add", for: .normal)
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(addButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 88),
            
            textField.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: addButton.leadingAnchor, constant: -8),
            
            dueDateButton.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 8),
            dueDateButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            notifySwitch.centerYAnchor.constraint(equalTo: dueDateButton.centerYAnchor),
            notifySwitch.leadingAnchor.constraint(equalTo: dueDateButton.trailingAnchor, constant: 16),
            
            addButton.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            addButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            addButton.widthAnchor.constraint(equalToConstant: 60),
            addButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    // MARK: - Action Methods
    @objc private func addButtonTapped() {
        submitTask()
    }
    
    @objc private func dueDateButtonTapped() {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.minimumDate = Date()
        
        if let dueDate = dueDate {
            datePicker.date = dueDate
        }
        
        let alertController = UIAlertController(title: "Set Due Date", message: "\n\n\n\n\n\n", preferredStyle: .alert)
        
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        alertController.view.addSubview(datePicker)
        
        NSLayoutConstraint.activate([
            datePicker.topAnchor.constraint(equalTo: alertController.view.topAnchor, constant: 50),
            datePicker.leadingAnchor.constraint(equalTo: alertController.view.leadingAnchor, constant: 0),
            datePicker.trailingAnchor.constraint(equalTo: alertController.view.trailingAnchor, constant: 0),
        ])
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alertController.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            self?.dueDate = nil
            self?.updateDueDateButton()
        })
        
        alertController.addAction(UIAlertAction(title: "Set", style: .default) { [weak self] _ in
            self?.dueDate = datePicker.date
            self?.updateDueDateButton()
        })
        
        window?.rootViewController?.present(alertController, animated: true)
    }
    
    @objc private func notifySwitchChanged(_ sender: UISwitch) {
        notify = sender.isOn
        
        // If notification is turned on but no due date, show due date picker
        if notify && dueDate == nil {
            dueDateButtonTapped()
        }
    }
    
    // MARK: - Helper Methods
    private func updateDueDateButton() {
        if let dueDate = dueDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            dueDateButton.setTitle(dateFormatter.string(from: dueDate), for: .normal)
        } else {
            dueDateButton.setTitle(nil, for: .normal)
            dueDateButton.setImage(UIImage(systemName: "calendar"), for: .normal)
            
            // Turn off notify switch if no due date
            notify = false
            notifySwitch.isOn = false
        }
    }
    
    private func submitTask() {
        guard let text = textField.text, !text.isEmpty else {
            return
        }
        
        delegate?.simpleTaskInputViewDidSubmit(self, taskTitle: text, dueDate: dueDate, notify: notify)
    }
    
    func clearInput() {
        textField.text = nil
        dueDate = nil
        notify = false
        notifySwitch.isOn = false
        updateDueDateButton()
    }
}

// MARK: - UITextFieldDelegate
extension SimpleTaskInputView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        submitTask()
        return true
    }
}

// MARK: - TaskCell
class TaskCell: UITableViewCell {
    
    // MARK: - Properties
    private let titleLabel = UILabel()
    private let dueDateLabel = UILabel()
    private let statusButton = UIButton(type: .system)
    
    // MARK: - Initializers
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    private func setupViews() {
        // Title Label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 0
        contentView.addSubview(titleLabel)
        
        // Due Date Label
        dueDateLabel.translatesAutoresizingMaskIntoConstraints = false
        dueDateLabel.font = UIFont.systemFont(ofSize: 12)
        dueDateLabel.textColor = .secondaryLabel
        contentView.addSubview(dueDateLabel)
        
        // Status Button
        statusButton.translatesAutoresizingMaskIntoConstraints = false
        statusButton.isUserInteractionEnabled = false
        contentView.addSubview(statusButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            statusButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statusButton.widthAnchor.constraint(equalToConstant: 24),
            statusButton.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: statusButton.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            dueDateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            dueDateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dueDateLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            dueDateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    // MARK: - Public Methods
    func configure(with task: Task) {
        titleLabel.text = task.title
        
        // Set due date text
        if let dueDate = task.dueDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            
            // Check if date is overdue
            let isOverdue = dueDate < Date() && task.status != .completed
            
            dueDateLabel.text = "Due: \(dateFormatter.string(from: dueDate))"
            
            if isOverdue {
                dueDateLabel.textColor = .systemRed
            } else if task.notifyUser {
                dueDateLabel.text = "🔔 \(dueDateLabel.text ?? "")"
                dueDateLabel.textColor = .secondaryLabel
            } else {
                dueDateLabel.textColor = .secondaryLabel
            }
        } else {
            dueDateLabel.text = nil
        }
        
        // Set status button image
        switch task.status {
        case .notStarted:
            statusButton.setImage(UIImage(systemName: "circle"), for: .normal)
            statusButton.tintColor = .systemGray
            titleLabel.attributedText = nil
        case .inProgress:
            statusButton.setImage(UIImage(systemName: "circle.dashed"), for: .normal)
            statusButton.tintColor = .systemOrange
            titleLabel.attributedText = nil
        case .completed:
            statusButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
            statusButton.tintColor = .systemGreen
            
            // Strikethrough for completed tasks
            let attributeString = NSMutableAttributedString(string: task.title)
            attributeString.addAttribute(.strikethroughStyle, value: 2, range: NSRange(location: 0, length: attributeString.length))
            titleLabel.attributedText = attributeString
            titleLabel.textColor = .secondaryLabel
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        titleLabel.attributedText = nil
        titleLabel.textColor = .label
        dueDateLabel.text = nil
        dueDateLabel.textColor = .secondaryLabel
        statusButton.setImage(nil, for: .normal)
    }
}