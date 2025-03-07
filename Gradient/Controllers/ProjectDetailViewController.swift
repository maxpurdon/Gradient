//
//  ProjectDetailViewController.swift
//  Gradient
//
//  Created by Andrew Purdon on 06/03/2025.
//


import UIKit

class ProjectDetailViewController: UIViewController {
    
    // MARK: - Properties
    private let project: Project
    private var tasks: [Task] = []
    private var notes: [Note] = []
    
    private let segmentedControl = UISegmentedControl(items: ["Tasks", "Notes"])
    private let containerView = UIView()
    
    private lazy var tasksViewController = TasksViewController(projectId: project.id)
    private lazy var notesViewController = NotesViewController(projectId: project.id)
    
    private var currentViewController: UIViewController?
    
    // MARK: - Initializers
    init(project: Project) {
        self.project = project
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
        showTasksView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    // MARK: - Setup Methods
    private func setupViews() {
        view.backgroundColor = .systemBackground
        title = project.name
        
        // Segmented Control
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        view.addSubview(segmentedControl)
        
        // Container View
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            containerView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        // Details Button
        let detailsButton = UIBarButtonItem(
            title: "Details",
            style: .plain,
            target: self,
            action: #selector(detailsButtonTapped)
        )
        navigationItem.rightBarButtonItem = detailsButton
    }
    
    // MARK: - Action Methods
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            showTasksView()
        case 1:
            showNotesView()
        default:
            break
        }
    }
    
    @objc private func detailsButtonTapped() {
        showProjectDetails()
    }
    
    private func showTasksView() {
        setupChildViewController(tasksViewController)
        currentViewController = tasksViewController
    }

    private func showNotesView() {
        setupChildViewController(notesViewController)
        currentViewController = notesViewController
    }
    
    // Keep your custom method named addChildViewController to avoid confusion
    // Use a completely different name to avoid any confusion with system methods
    private func setupChildViewController(_ childViewController: UIViewController) {
        // Remove current child view controller
        if let currentViewController = currentViewController {
            currentViewController.willMove(toParent: nil)
            currentViewController.view.removeFromSuperview()
            currentViewController.removeFromParent()
        }
        
        // Add new child view controller
        addChild(childViewController)  // Use system method here
        childViewController.view.frame = containerView.bounds
        childViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(childViewController.view)
        childViewController.didMove(toParent: self)
    }
    
    private func showProjectDetails() {
        let detailsView = UIView()
        detailsView.backgroundColor = .systemBackground
        detailsView.layer.cornerRadius = 12
        
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        detailsView.addSubview(scrollView)
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        
        // Add status label
        let statusLabel = createDetailLabel(title: "Status", value: project.status.rawValue)
        stackView.addArrangedSubview(statusLabel)
        
        // Add description label
        let descriptionLabel = createDetailLabel(title: "Description", value: project.description.isEmpty ? "No description" : project.description)
        stackView.addArrangedSubview(descriptionLabel)
        
        // Add workshops section
        if !project.workshops.isEmpty {
            let workshopsView = createTagsSection(title: "Workshops", tags: project.workshops)
            stackView.addArrangedSubview(workshopsView)
        }
        
        // Add materials needed section
        if !project.materialsNeeded.isEmpty {
            let materialsNeededView = createTagsSection(title: "Materials Needed", tags: project.materialsNeeded)
            stackView.addArrangedSubview(materialsNeededView)
        }
        
        // Add materials found section
        if !project.materialsFound.isEmpty {
            let materialsFoundView = createTagsSection(title: "Materials Found", tags: project.materialsFound)
            stackView.addArrangedSubview(materialsFoundView)
        }
        
        // Add dates section
        let createdDate = DateFormatter.localizedString(from: project.createdAt, dateStyle: .medium, timeStyle: .short)
        let updatedDate = DateFormatter.localizedString(from: project.updatedAt, dateStyle: .medium, timeStyle: .short)
        
        let datesLabel = createDetailLabel(title: "Created", value: createdDate)
        stackView.addArrangedSubview(datesLabel)
        
        let updatedLabel = createDetailLabel(title: "Last Updated", value: updatedDate)
        stackView.addArrangedSubview(updatedLabel)
        
        // Add constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: detailsView.topAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: detailsView.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: detailsView.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: detailsView.bottomAnchor, constant: -16),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Present as a bottom sheet
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.view.addSubview(detailsView)
        
        detailsView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            detailsView.topAnchor.constraint(equalTo: alertController.view.topAnchor, constant: 20),
            detailsView.leadingAnchor.constraint(equalTo: alertController.view.leadingAnchor, constant: 8),
            detailsView.trailingAnchor.constraint(equalTo: alertController.view.trailingAnchor, constant: -8),
            detailsView.heightAnchor.constraint(equalToConstant: 400)
        ])
        
        alertController.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func createDetailLabel(title: String, value: String) -> UIView {
        let containerView = UIView()
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 17)
        valueLabel.numberOfLines = 0
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    private func createTagsSection(title: String, tags: [String]) -> UIView {
        let containerView = UIView()
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        let tagView = TagDisplayView(tags: tags)
        tagView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(tagView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            tagView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            tagView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            tagView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            tagView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
}

// MARK: - TagDisplayView
class TagDisplayView: UIView {
    
    // MARK: - Properties
    private let flowLayout = UICollectionViewFlowLayout()
    private var collectionView: UICollectionView!
    private let tags: [String]
    
    // MARK: - Initializers
    init(tags: [String]) {
        self.tags = tags
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    private func setupView() {
        flowLayout.scrollDirection = .horizontal
        flowLayout.estimatedItemSize = CGSize(width: 100, height: 30)
        flowLayout.minimumInteritemSpacing = 8
        flowLayout.minimumLineSpacing = 8
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(TagCell.self, forCellWithReuseIdentifier: "TagCell")
        
        addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension TagDisplayView: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagCell", for: indexPath) as? TagCell else {
            return UICollectionViewCell()
        }
        
        cell.configure(with: tags[indexPath.item])
        return cell
    }
}

// MARK: - TagCell
class TagCell: UICollectionViewCell {
    
    // MARK: - Properties
    private let label = UILabel()
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    private func setupView() {
        contentView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        contentView.layer.cornerRadius = 15
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.2).cgColor
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .systemBlue
        contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5)
        ])
    }
    
    // MARK: - Public Methods
    func configure(with text: String) {
        label.text = text
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let targetSize = CGSize(width: layoutAttributes.frame.width, height: 30)
        layoutAttributes.frame.size = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        return layoutAttributes
    }
}
