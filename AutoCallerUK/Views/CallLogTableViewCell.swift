//
//  CallLogTableViewCell.swift
//  HealthcareCallApp
//
//  Custom cell for call log entries
//

import UIKit

class CallLogTableViewCell: UITableViewCell {
    
    static let identifier = "CallLogTableViewCell"
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.shadowRadius = 3
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let statusIndicatorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let providerNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let phoneNumberLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timestampLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let attemptsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let detailsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let callAgainButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "phone.fill"), for: .normal)
        button.tintColor = .systemGreen
        button.backgroundColor = .systemGreen.withAlphaComponent(0.1)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Properties
    
    private var callLogEntry: CallLogEntry?
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
        setupActions()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        
        containerView.addSubview(statusIndicatorView)
        containerView.addSubview(providerNameLabel)
        containerView.addSubview(statusLabel)
        containerView.addSubview(phoneNumberLabel)
        containerView.addSubview(timestampLabel)
        containerView.addSubview(detailsStackView)
        containerView.addSubview(callAgainButton)
        
        detailsStackView.addArrangedSubview(durationLabel)
        detailsStackView.addArrangedSubview(attemptsLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            // Status indicator
            statusIndicatorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            statusIndicatorView.topAnchor.constraint(equalTo: containerView.topAnchor),
            statusIndicatorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            statusIndicatorView.widthAnchor.constraint(equalToConstant: 4),
            
            // Provider name label
            providerNameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            providerNameLabel.leadingAnchor.constraint(equalTo: statusIndicatorView.trailingAnchor, constant: 12),
            providerNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusLabel.leadingAnchor, constant: -8),
            
            // Status label
            statusLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            statusLabel.trailingAnchor.constraint(equalTo: callAgainButton.leadingAnchor, constant: -8),
            statusLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            statusLabel.heightAnchor.constraint(equalToConstant: 20),
            
            // Call again button
            callAgainButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            callAgainButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            callAgainButton.widthAnchor.constraint(equalToConstant: 32),
            callAgainButton.heightAnchor.constraint(equalToConstant: 32),
            
            // Phone number label
            phoneNumberLabel.topAnchor.constraint(equalTo: providerNameLabel.bottomAnchor, constant: 4),
            phoneNumberLabel.leadingAnchor.constraint(equalTo: statusIndicatorView.trailingAnchor, constant: 12),
            phoneNumberLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            // Timestamp label
            timestampLabel.topAnchor.constraint(equalTo: phoneNumberLabel.bottomAnchor, constant: 4),
            timestampLabel.leadingAnchor.constraint(equalTo: statusIndicatorView.trailingAnchor, constant: 12),
            timestampLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            // Details stack view
            detailsStackView.topAnchor.constraint(equalTo: timestampLabel.bottomAnchor, constant: 4),
            detailsStackView.leadingAnchor.constraint(equalTo: statusIndicatorView.trailingAnchor, constant: 12),
            detailsStackView.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -12),
            detailsStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }
    
    private func setupActions() {
        callAgainButton.addTarget(self, action: #selector(callAgainButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Configuration
    
    func configure(with entry: CallLogEntry) {
        self.callLogEntry = entry
        
        providerNameLabel.text = entry.providerName
        phoneNumberLabel.text = entry.phoneNumber
        timestampLabel.text = entry.formattedTimestamp
        
        // Configure status
        configureStatus(entry.callStatus)
        
        // Configure duration
        if entry.duration > 0 {
            durationLabel.text = "Duration: \(entry.formattedDuration)"
            durationLabel.isHidden = false
        } else {
            durationLabel.isHidden = true
        }
        
        // Configure attempts
        if entry.attempts > 1 {
            attemptsLabel.text = "Attempts: \(entry.attempts)"
            attemptsLabel.isHidden = false
        } else {
            attemptsLabel.isHidden = true
        }
        
        // Show/hide call again button based on phone number availability
        callAgainButton.isHidden = entry.phoneNumber.isEmpty
    }
    
    private func configureStatus(_ status: CallStatus) {
        statusLabel.text = status.displayName.uppercased()
        
        switch status {
        case .success:
            statusIndicatorView.backgroundColor = .systemGreen
            statusLabel.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
            statusLabel.textColor = .systemGreen
            
        case .failed:
            statusIndicatorView.backgroundColor = .systemRed
            statusLabel.backgroundColor = UIColor.systemRed.withAlphaComponent(0.2)
            statusLabel.textColor = .systemRed
            
        case .inProgress:
            statusIndicatorView.backgroundColor = .systemBlue
            statusLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
            statusLabel.textColor = .systemBlue
        }
    }
    
    // MARK: - Actions
    
    @objc private func callAgainButtonTapped() {
        guard let entry = callLogEntry else { return }
        makeCall(to: entry.phoneNumber)
    }
    
    private func makeCall(to phoneNumber: String) {
        let cleanNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
        
        guard let url = URL(string: "tel://\(cleanNumber)") else {
            showAlert(message: "Invalid phone number")
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            showAlert(message: "Device cannot make phone calls")
        }
    }
    
    private func showAlert(message: String) {
        guard let viewController = findViewController() else { return }
        
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alert, animated: true)
    }
    
    // MARK: - Animation
    
    func animateStatusChange() {
        UIView.animate(withDuration: 0.3, animations: {
            self.statusLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                self.statusLabel.transform = .identity
            }
        }
    }
    
    func highlightForNewEntry() {
        containerView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        
        UIView.animate(withDuration: 2.0, delay: 0.5, options: .curveEaseOut, animations: {
            self.containerView.backgroundColor = .systemBackground
        })
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        providerNameLabel.text = nil
        phoneNumberLabel.text = nil
        timestampLabel.text = nil
        durationLabel.text = nil
        attemptsLabel.text = nil
        statusLabel.text = nil
        
        durationLabel.isHidden = false
        attemptsLabel.isHidden = false
        callAgainButton.isHidden = false
        
        containerView.backgroundColor = .systemBackground
        statusLabel.transform = .identity
        
        callLogEntry = nil
    }
}

// MARK: - Helper Extensions

extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}

// MARK: - Call Log Entry Extensions

extension CallLogEntry {
    
    var isRecent: Bool {
        let timeInterval = Date().timeIntervalSince(timestamp)
        return timeInterval < 300 // 5 minutes
    }
    
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    var detailedTimeString: String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(timestamp) {
            formatter.timeStyle = .short
            return "Today at \(formatter.string(from: timestamp))"
        } else if Calendar.current.isDateInYesterday(timestamp) {
            formatter.timeStyle = .short
            return "Yesterday at \(formatter.string(from: timestamp))"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: timestamp)
        }
    }
}