//
//  MainDashboardViewController.swift
//  HealthcareCallApp
//
//  Main dashboard screen with call setups list
//

import UIKit
import CoreData

class MainDashboardViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var callLogButton: UIBarButtonItem!
    
    // MARK: - Properties
    private let dataManager = DataManager.shared
    private let callScheduler = CallScheduler.shared
    private let validationService = ValidationService.shared
    
    private var callSetups: [CallSetup] = []
    private var filteredSetups: [CallSetup] = []
    private var isSearching = false
    
    private lazy var emptyStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView(image: UIImage(systemName: "phone.badge.plus"))
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "No Call Setups"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        
        let messageLabel = UILabel()
        messageLabel.text = "Tap the + button to create your first call setup"
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(messageLabel)
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 80),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
        
        return view
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupSearchBar()
        setupNotifications()
        loadCallSetups()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCallSetups()
        updateEmptyState()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Call Manager"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Setup navigation bar buttons
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonTapped)
        )
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "📋 Call Log",
            style: .plain,
            target: self,
            action: #selector(callLogButtonTapped)
        )
        
        view.backgroundColor = .systemGroupedBackground
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CallSetupTableViewCell.self, forCellReuseIdentifier: CallSetupTableViewCell.identifier)
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        
        // Add refresh control
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = "Search setups..."
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundColor = .clear
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(callCompleted(_:)),
            name: .callCompleted,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(setupSnoozed(_:)),
            name: .setupSnoozed,
            object: nil
        )
    }
    
    // MARK: - Data Loading
    
    private func loadCallSetups() {
        callSetups = dataManager.fetchAllCallSetups()
        updateFilteredSetups()
        updateEmptyState()
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
        }
    }
    
    private func updateFilteredSetups() {
        if isSearching && !searchBar.text!.isEmpty {
            filteredSetups = dataManager.searchCallSetups(query: searchBar.text!)
        } else {
            filteredSetups = callSetups
            isSearching = false
        }
    }
    
    private func updateEmptyState() {
        let shouldShowEmpty = filteredSetups.isEmpty
        
        if shouldShowEmpty {
            if emptyStateView.superview == nil {
                view.addSubview(emptyStateView)
                NSLayoutConstraint.activate([
                    emptyStateView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
                    emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    emptyStateView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
                ])
            }
            emptyStateView.isHidden = false
            tableView.isHidden = true
        } else {
            emptyStateView.isHidden = true
            tableView.isHidden = false
        }
    }
    
    // MARK: - Actions
    
    @objc private func addButtonTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let setupVC = storyboard.instantiateViewController(withIdentifier: "CallSetupViewController") as? CallSetupViewController {
            setupVC.delegate = self
            let navController = UINavigationController(rootViewController: setupVC)
            present(navController, animated: true)
        }
    }
    
    @objc private func callLogButtonTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let logVC = storyboard.instantiateViewController(withIdentifier: "CallLogViewController") as? CallLogViewController {
            navigationController?.pushViewController(logVC, animated: true)
        }
    }
    
    @objc private func refreshData() {
        loadCallSetups()
    }
    
    // MARK: - Setup Actions
    
    private func editSetup(_ setup: CallSetup) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let setupVC = storyboard.instantiateViewController(withIdentifier: "CallSetupViewController") as? CallSetupViewController {
            setupVC.callSetup = setup
            setupVC.delegate = self
            let navController = UINavigationController(rootViewController: setupVC)
            present(navController, animated: true)
        }
    }
    
    private func deleteSetup(_ setup: CallSetup) {
        let alert = UIAlertController(
            title: "Delete Setup",
            message: "Are you sure you want to delete this call setup?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.performDelete(setup)
        })
        
        present(alert, animated: true)
    }
    
    private func performDelete(_ setup: CallSetup) {
        // Cancel any scheduled notifications
        callScheduler.cancelNotifications(for: setup)
        
        // Delete from Core Data
        dataManager.deleteCallSetup(setup)
        
        // Reload data
        loadCallSetups()
        
        // Show success message
        showMessage("Setup deleted successfully", type: .success)
    }
    
    private func toggleSnooze(_ setup: CallSetup) {
        if setup.isCurrentlySnoozed {
            callScheduler.unsnoozeSetup(setup)
            showMessage("Setup unsnoozed", type: .success)
        } else {
            callScheduler.snoozeSetup(setup)
            showMessage("Setup snoozed for 1 hour", type: .success)
        }
        
        loadCallSetups()
    }
    
    private func callNow(_ setup: CallSetup) {
        callScheduler.initiateCall(for: setup)
    }
    
    // MARK: - Notification Handlers
    
    @objc private func callCompleted(_ notification: Notification) {
        DispatchQueue.main.async {
            self.loadCallSetups()
        }
    }
    
    @objc private func setupSnoozed(_ notification: Notification) {
        DispatchQueue.main.async {
            self.loadCallSetups()
        }
    }
    
    // MARK: - Helper Methods
    
    private func showMessage(_ message: String, type: MessageType) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        
        // Auto dismiss after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            alert.dismiss(animated: true)
        }
    }
    
    enum MessageType {
        case success
        case error
        case info
    }
}

// MARK: - UITableViewDataSource

extension MainDashboardViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredSetups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CallSetupTableViewCell.identifier, for: indexPath) as? CallSetupTableViewCell else {
            return UITableViewCell()
        }
        
        let setup = filteredSetups[indexPath.row]
        cell.configure(with: setup)
        cell.delegate = self
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension MainDashboardViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let setup = filteredSetups[indexPath.row]
        editSetup(setup)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let setup = filteredSetups[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
            self.deleteSetup(setup)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        
        let snoozeAction = UIContextualAction(style: .normal, title: setup.isCurrentlySnoozed ? "Unsnooze" : "Snooze") { _, _, completion in
            self.toggleSnooze(setup)
            completion(true)
        }
        snoozeAction.image = UIImage(systemName: setup.isCurrentlySnoozed ? "bell" : "bell.slash")
        snoozeAction.backgroundColor = setup.isCurrentlySnoozed ? .systemBlue : .systemOrange
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { _, _, completion in
            self.editSetup(setup)
            completion(true)
        }
        editAction.image = UIImage(systemName: "pencil")
        editAction.backgroundColor = .systemGray
        
        return UISwipeActionsConfiguration(actions: [deleteAction, snoozeAction, editAction])
    }
}

// MARK: - UISearchBarDelegate

extension MainDashboardViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        isSearching = !searchText.isEmpty
        updateFilteredSetups()
        updateEmptyState()
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        isSearching = false
        updateFilteredSetups()
        updateEmptyState()
        tableView.reloadData()
    }
}

// MARK: - CallSetupTableViewCellDelegate

extension MainDashboardViewController: CallSetupTableViewCellDelegate {
    
    func didTapEdit(for setup: CallSetup) {
        editSetup(setup)
    }
    
    func didTapSnooze(for setup: CallSetup) {
        toggleSnooze(setup)
    }
    
    func didTapDelete(for setup: CallSetup) {
        deleteSetup(setup)
    }
    
    func didTapCall(for setup: CallSetup) {
        callNow(setup)
    }
}

// MARK: - CallSetupViewControllerDelegate

extension MainDashboardViewController: CallSetupViewControllerDelegate {
    
    func didSaveCallSetup(_ setup: CallSetup) {
        loadCallSetups()
        showMessage("Setup saved successfully", type: .success)
    }
    
    func didCancelCallSetup() {
        // No action needed
    }
}

// MARK: - Protocols

protocol CallSetupTableViewCellDelegate: AnyObject {
    func didTapEdit(for setup: CallSetup)
    func didTapSnooze(for setup: CallSetup)
    func didTapDelete(for setup: CallSetup)
    func didTapCall(for setup: CallSetup)
}

protocol CallSetupViewControllerDelegate: AnyObject {
    func didSaveCallSetup(_ setup: CallSetup)
    func didCancelCallSetup()
}