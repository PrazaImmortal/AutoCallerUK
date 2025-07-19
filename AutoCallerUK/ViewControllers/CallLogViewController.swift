//
//  CallLogViewController.swift
//  HealthcareCallApp
//
//  Call history and logs screen
//

import UIKit

class CallLogViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var filterContainerView: UIView!
    @IBOutlet weak var statusFilterSegmentedControl: UISegmentedControl!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var clearFilterButton: UIButton!
    @IBOutlet weak var exportButton: UIBarButtonItem!
    @IBOutlet weak var clearLogButton: UIBarButtonItem!
    
    // MARK: - Properties
    private let dataManager = DataManager.shared
    private let callStateMonitor = CallStateMonitor.shared
    
    private var callLogs: [CallLogEntry] = []
    private var filteredLogs: [CallLogEntry] = []
    private var isFiltering = false
    
    private lazy var emptyStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView(image: UIImage(systemName: "phone.badge.checkmark"))
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "No Call History"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        
        let messageLabel = UILabel()
        messageLabel.text = "Call logs will appear here once you start making calls"
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
        setupFilters()
        setupNotifications()
        loadCallLogs()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCallLogs()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Call Log"
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                image: UIImage(systemName: "square.and.arrow.up"),
                style: .plain,
                target: self,
                action: #selector(exportButtonTapped)
            ),
            UIBarButtonItem(
                image: UIImage(systemName: "trash"),
                style: .plain,
                target: self,
                action: #selector(clearLogButtonTapped)
            )
        ]
        
        view.backgroundColor = .systemGroupedBackground
        
        // Setup filter container
        filterContainerView.backgroundColor = .systemBackground
        filterContainerView.layer.cornerRadius = 12
        filterContainerView.layer.shadowColor = UIColor.black.cgColor
        filterContainerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        filterContainerView.layer.shadowRadius = 4
        filterContainerView.layer.shadowOpacity = 0.1
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CallLogTableViewCell.self, forCellReuseIdentifier: CallLogTableViewCell.identifier)
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        
        // Add refresh control
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    private func setupFilters() {
        // Status filter
        statusFilterSegmentedControl.removeAllSegments()
        statusFilterSegmentedControl.insertSegment(withTitle: "All", at: 0, animated: false)
        statusFilterSegmentedControl.insertSegment(withTitle: "Success", at: 1, animated: false)
        statusFilterSegmentedControl.insertSegment(withTitle: "Failed", at: 2, animated: false)
        statusFilterSegmentedControl.selectedSegmentIndex = 0
        statusFilterSegmentedControl.addTarget(self, action: #selector(statusFilterChanged), for: .valueChanged)
        
        // Date picker
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.addTarget(self, action: #selector(dateFilterChanged), for: .valueChanged)
        
        // Clear filter button
        clearFilterButton.setTitle("Clear Filters", for: .normal)
        clearFilterButton.setTitleColor(.systemBlue, for: .normal)
        clearFilterButton.addTarget(self, action: #selector(clearFiltersButtonTapped), for: .touchUpInside)
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
            selector: #selector(callStatisticsUpdated(_:)),
            name: .callStatisticsUpdated,
            object: nil
        )
    }
    
    // MARK: - Data Loading
    
    private func loadCallLogs() {
        callLogs = dataManager.fetchAllCallLogs()
        applyFilters()
        updateEmptyState()
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
        }
    }
    
    private func applyFilters() {
        var filtered = callLogs
        
        // Apply status filter
        let selectedStatusIndex = statusFilterSegmentedControl.selectedSegmentIndex
        if selectedStatusIndex > 0 {
            let status: CallStatus = selectedStatusIndex == 1 ? .success : .failed
            filtered = filtered.filter { $0.callStatus == status }
        }
        
        // Apply date filter if a specific date is selected
        let calendar = Calendar.current
        let selectedDate = datePicker.date
        let today = Date()
        
        if !calendar.isDate(selectedDate, inSameDayAs: today) {
            filtered = filtered.filter { entry in
                calendar.isDate(entry.timestamp, inSameDayAs: selectedDate)
            }
        }
        
        filteredLogs = filtered
        isFiltering = selectedStatusIndex > 0 || !calendar.isDate(selectedDate, inSameDayAs: today)
    }
    
    private func updateEmptyState() {
        let shouldShowEmpty = filteredLogs.isEmpty
        
        if shouldShowEmpty {
            if emptyStateView.superview == nil {
                view.addSubview(emptyStateView)
                NSLayoutConstraint.activate([
                    emptyStateView.topAnchor.constraint(equalTo: filterContainerView.bottomAnchor, constant: 20),
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
    
    @objc private func statusFilterChanged() {
        applyFilters()
        updateEmptyState()
        tableView.reloadData()
    }
    
    @objc private func dateFilterChanged() {
        applyFilters()
        updateEmptyState()
        tableView.reloadData()
    }
    
    @objc private func clearFiltersButtonTapped() {
        statusFilterSegmentedControl.selectedSegmentIndex = 0
        datePicker.date = Date()
        applyFilters()
        updateEmptyState()
        tableView.reloadData()
    }
    
    @objc private func exportButtonTapped() {
        exportCallLogs()
    }
    
    @objc private func clearLogButtonTapped() {
        let alert = UIAlertController(
            title: "Clear Call Log",
            message: "Are you sure you want to clear all call history? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
            self.clearAllLogs()
        })
        
        present(alert, animated: true)
    }
    
    @objc private func refreshData() {
        loadCallLogs()
    }
    
    // MARK: - Log Management
    
    private func clearAllLogs() {
        dataManager.clearAllCallLogs()
        loadCallLogs()
        showMessage("Call log cleared successfully", type: .success)
    }
    
    private func deleteLogEntry(_ entry: CallLogEntry) {
        dataManager.deleteCallLogEntry(entry)
        loadCallLogs()
        showMessage("Log entry deleted", type: .success)
    }
    
    private func exportCallLogs() {
        guard !callLogs.isEmpty else {
            showMessage("No call log data to export", type: .error)
            return
        }
        
        let csvContent = dataManager.exportCallLogsToCSV()
        
        let fileName = "call-log-\(DateFormatter.fileNameFormatter.string(from: Date())).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
            
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            activityVC.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItems?.first
            
            present(activityVC, animated: true) {
                // Clean up temp file after sharing
                try? FileManager.default.removeItem(at: tempURL)
            }
            
            showMessage("Call log exported successfully", type: .success)
        } catch {
            showMessage("Failed to export call log", type: .error)
        }
    }
    
    // MARK: - Statistics
    
    private func showStatistics() {
        let stats = callStateMonitor.getCallStatistics()
        
        let alert = UIAlertController(title: "Call Statistics", message: nil, preferredStyle: .alert)
        
        let message = """
        Total Calls: \(stats.totalCalls)
        Successful: \(stats.successfulCalls)
        Failed: \(stats.failedCalls)
        Success Rate: \(String(format: "%.1f", stats.successRate))%
        Average Duration: \(stats.formattedAverageDuration)
        Today's Calls: \(stats.todaysCalls)
        """
        
        alert.message = message
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alert, animated: true)
    }
    
    // MARK: - Notification Handlers
    
    @objc private func callCompleted(_ notification: Notification) {
        DispatchQueue.main.async {
            self.loadCallLogs()
        }
    }
    
    @objc private func callStatisticsUpdated(_ notification: Notification) {
        DispatchQueue.main.async {
            self.loadCallLogs()
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

extension CallLogViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredLogs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CallLogTableViewCell.identifier, for: indexPath) as? CallLogTableViewCell else {
            return UITableViewCell()
        }
        
        let logEntry = filteredLogs[indexPath.row]
        cell.configure(with: logEntry)
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension CallLogViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let logEntry = filteredLogs[indexPath.row]
        showLogDetails(logEntry)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let logEntry = filteredLogs[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
            self.deleteLogEntry(logEntry)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        
        let callAgainAction = UIContextualAction(style: .normal, title: "Call") { _, _, completion in
            self.callAgain(logEntry)
            completion(true)
        }
        callAgainAction.image = UIImage(systemName: "phone")
        callAgainAction.backgroundColor = .systemGreen
        
        return UISwipeActionsConfiguration(actions: [deleteAction, callAgainAction])
    }
    
    private func showLogDetails(_ logEntry: CallLogEntry) {
        let alert = UIAlertController(title: "Call Details", message: nil, preferredStyle: .alert)
        
        let message = """
        Provider: \(logEntry.providerName)
        Phone: \(logEntry.phoneNumber)
        Status: \(logEntry.callStatus.displayName)
        Duration: \(logEntry.formattedDuration)
        Attempts: \(logEntry.attempts)
        Time: \(logEntry.formattedTimestamp)
        """
        
        alert.message = message
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if !logEntry.phoneNumber.isEmpty {
            alert.addAction(UIAlertAction(title: "Call Again", style: .default) { _ in
                self.callAgain(logEntry)
            })
        }
        
        present(alert, animated: true)
    }
    
    private func callAgain(_ logEntry: CallLogEntry) {
        let cleanNumber = logEntry.phoneNumber.replacingOccurrences(of: " ", with: "")
        
        guard let url = URL(string: "tel://\(cleanNumber)") else {
            showMessage("Invalid phone number", type: .error)
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            showMessage("Device cannot make phone calls", type: .error)
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}