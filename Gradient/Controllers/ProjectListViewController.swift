//
//  ProjectListViewController.swift
//  Gradient
//
//  Created by Andrew Purdon on 06/03/2025.
//


import UIKit

class ProjectListViewController: UIViewController {
    
    // MARK: - Properties
    private var collectionView: UICollectionView!
    private var projects: [Project] = []
    private var tasks: [String: [Task]] = [:]
    private let searchController = UISearchController(searchResultsController: nil)
    private var filteredProjects: [Project] = []
    private var isSearching: Bool = false
    private var searchScope: SearchScope = .all
    
    enum SearchScope: String, CaseIterable {
        case all = "All"
        case name = "Name"
        case description = "Description"
        case workshops = "Workshops"
        case materials = "Materials"
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupNavigationBar()
        setupSearchController()
        setupAddButton()
        observeProjects()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    // MARK: - Setup Methods
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        
        // Calculate cell size for 2 cells per row with padding
        let padding: CGFloat = 16
        let cellWidth = (view.bounds.width - padding * 3) / 2 // 3 paddings: left, middle, right
        let cellHeight: CGFloat = 150
        
        layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
        layout.sectionInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        layout.minimumLineSpacing = padding
        layout.minimumInteritemSpacing = padding
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ProjectTileCell.self, forCellWithReuseIdentifier: "ProjectTileCell")
        
        view.addSubview(collectionView)
    }
    
    private func setupNavigationBar() {
        title = "GMax Projects"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Projects"
        
        searchController.searchBar.scopeButtonTitles = SearchScope.allCases.map { $0.rawValue }
        searchController.searchBar.delegate = self
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        definesPresentationContext = true
    }
    
    private func setupAddButton() {
        let addButton = UIButton(type: .system)
        addButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addButton.tintColor = .systemBlue
        addButton.contentHorizontalAlignment = .fill
        addButton.contentVerticalAlignment = .fill
        addButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        
        view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            addButton.widthAnchor.constraint(equalToConstant: 60),
            addButton.heightAnchor.constraint(equalToConstant: 60),
            addButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Data Methods
    private func observeProjects() {
        FirebaseManager.shared.observeProjects { [weak self] projects in
            guard let self = self else { return }
            self.projects = projects.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
            
            // Observe tasks for each project to get incomplete task counts
            for project in projects {
                self.observeTasks(forProject: project.id)
            }
            
            self.filterProjects()
        }
    }
    
    private func observeTasks(forProject projectId: String) {
        FirebaseManager.shared.observeTasks(forProject: projectId) { [weak self] tasks in
            guard let self = self else { return }
            self.tasks[projectId] = tasks
            self.collectionView.reloadData()
        }
    }
    
    private func filterProjects() {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
            filteredProjects = projects
            isSearching = false
            collectionView.reloadData()
            return
        }
        
        isSearching = true
        
        switch searchScope {
        case .all:
            filteredProjects = projects.filter { project in
                return project.name.lowercased().contains(searchText.lowercased()) ||
                       project.description.lowercased().contains(searchText.lowercased()) ||
                       project.workshops.joined(separator: " ").lowercased().contains(searchText.lowercased()) ||
                       project.materialsNeeded.joined(separator: " ").lowercased().contains(searchText.lowercased()) ||
                       project.materialsFound.joined(separator: " ").lowercased().contains(searchText.lowercased())
            }
        case .name:
            filteredProjects = projects.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        case .description:
            filteredProjects = projects.filter { $0.description.lowercased().contains(searchText.lowercased()) }
        case .workshops:
            filteredProjects = projects.filter { $0.workshops.joined(separator: " ").lowercased().contains(searchText.lowercased()) }
        case .materials:
            filteredProjects = projects.filter { 
                $0.materialsNeeded.joined(separator: " ").lowercased().contains(searchText.lowercased()) ||
                $0.materialsFound.joined(separator: " ").lowercased().contains(searchText.lowercased())
            }
        }
        
        collectionView.reloadData()
    }
    
    // MARK: - Action Methods
    @objc private func addButtonTapped() {
        let addProjectVC = AddProjectViewController()
        addProjectVC.modalPresentationStyle = .formSheet
        present(addProjectVC, animated: true)
    }
    
    private func showProjectOptions(forProject project: Project, sender: UIView) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }
        
        alertController.addAction(UIAlertAction(title: "View Project", style: .default) { [weak self] _ in
            self?.navigateToProject(project)
        })
        
        alertController.addAction(UIAlertAction(title: "Edit Project", style: .default) { [weak self] _ in
            self?.editProject(project)
        })
        
        alertController.addAction(UIAlertAction(title: "Delete Project", style: .destructive) { [weak self] _ in
            self?.confirmDeleteProject(project)
        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alertController, animated: true)
    }
    
    private func navigateToProject(_ project: Project) {
        let projectDetailVC = ProjectDetailViewController(project: project)
        navigationController?.pushViewController(projectDetailVC, animated: true)
    }
    
    private func editProject(_ project: Project) {
        let editProjectVC = AddProjectViewController(project: project)
        editProjectVC.modalPresentationStyle = .formSheet
        present(editProjectVC, animated: true)
    }
    
    private func confirmDeleteProject(_ project: Project) {
        let alertController = UIAlertController(
            title: "Delete Project",
            message: "Please type 'delete' to confirm deletion of project '\(project.name)'",
            preferredStyle: .alert
        )
        
        alertController.addTextField { textField in
            textField.placeholder = "Type 'delete' to confirm"
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alertController.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self, weak alertController] _ in
            guard let self = self,
                  let textField = alertController?.textFields?.first,
                  textField.text?.lowercased() == "delete" else {
                return
            }
            
            self.deleteProject(project)
        })
        
        present(alertController, animated: true)
    }
    
    private func deleteProject(_ project: Project) {
        FirebaseManager.shared.deleteProject(project.id) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Projects will be updated via the Firebase observer
                    break
                case .failure(let error):
                    let errorAlert = UIAlertController(
                        title: "Error",
                        message: "Failed to delete project: \(error.localizedDescription)",
                        preferredStyle: .alert
                    )
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(errorAlert, animated: true)
                }
            }
        }
    }
}

// MARK: - UICollectionView Delegate & DataSource
extension ProjectListViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isSearching ? filteredProjects.count : projects.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProjectTileCell", for: indexPath) as? ProjectTileCell else {
            return UICollectionViewCell()
        }
        
        let project = isSearching ? filteredProjects[indexPath.item] : projects[indexPath.item]
        let projectTasks = tasks[project.id] ?? []
        let incompleteTasks = projectTasks.filter { $0.status != .completed }
        
        cell.configure(with: project, incompleteTaskCount: incompleteTasks.count)
        
        // Setup long press gesture
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        cell.addGestureRecognizer(longPressGesture)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let project = isSearching ? filteredProjects[indexPath.item] : projects[indexPath.item]
        navigateToProject(project)
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            guard let cell = gesture.view as? ProjectTileCell,
                  let indexPath = collectionView.indexPath(for: cell) else {
                return
            }
            
            let project = isSearching ? filteredProjects[indexPath.item] : projects[indexPath.item]
            showProjectOptions(forProject: project, sender: cell)
        }
    }
}

// MARK: - Search Results Updating & Search Bar Delegate
extension ProjectListViewController: UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let scopeIndex = searchBar.selectedScopeButtonIndex
        searchScope = SearchScope.allCases[scopeIndex]
        
        filterProjects()
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        searchScope = SearchScope.allCases[selectedScope]
        filterProjects()
    }
}

// MARK: - ProjectTileCell
class ProjectTileCell: UICollectionViewCell {
    private let titleLabel = UILabel()
    private let statusLabel = UILabel()
    private let taskCountLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 12
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 4
        contentView.layer.shadowOpacity = 0.1
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.numberOfLines = 2
        
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        
        taskCountLabel.translatesAutoresizingMaskIntoConstraints = false
        taskCountLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(statusLabel)
        contentView.addSubview(taskCountLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            taskCountLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            taskCountLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            taskCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    func configure(with project: Project, incompleteTaskCount: Int) {
        titleLabel.text = project.name
        statusLabel.text = project.status.rawValue
        
        // Set cell background color based on project status
        contentView.backgroundColor = project.status.color.withAlphaComponent(0.15)
        
        // Set status label text color
        statusLabel.textColor = project.status.color
        
        // Set task count
        if incompleteTaskCount == 0 {
            taskCountLabel.text = "No tasks remaining"
            taskCountLabel.textColor = .systemGreen
        } else {
            taskCountLabel.text = "\(incompleteTaskCount) task\(incompleteTaskCount == 1 ? "" : "s") remaining"
            taskCountLabel.textColor = .systemOrange
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        statusLabel.text = nil
        taskCountLabel.text = nil
        contentView.backgroundColor = .systemBackground
    }
}