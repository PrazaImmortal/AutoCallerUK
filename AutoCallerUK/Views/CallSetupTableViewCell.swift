//
//  CallSetupTableViewCell.swift
//  HealthcareCallApp
//
//  Custom cell for call setup list
//

import UIKit

class CallSetupTableViewCell: UITableViewCell {
    
    static let identifier = "CallSetupTableViewCell"
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let phoneLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nextCallLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let snoozeBadge: UILabel = {
        let label = UILabel()
        label.text = "Snoozed"
        label.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        label.textColor = .white
        label.backgroundColor = .systemRed
        label.textAlignment = .center
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let buttonsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let editButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Edit", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.setTitleColor(.systemBlue, for: .normal)
        button.backgroundColor = .systemBackground
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let snoozeButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Delete", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemRed.cgColor
        button.setTitleColor(.systemRed, for: .normal)
        button.backgroundColor = .systemBackground
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let callButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("📞 Call", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.layer.cornerRadius = 8
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Properties
    
    weak var delegate: CallSetupTableViewCellDelegate?
    private var callSetup: CallSetup?
    
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
        
        containerView.addSubview(nameLabel)
        containerView.addSubview(phoneLabel)
        containerView.addSubview(timeLabel)
        containerView.addSubview(nextCallLabel)
        containerView.addSubview(snoozeBadge)
        containerView.addSubview(buttonsStackView)
        
        buttonsStackView.addArrangedSubview(editButton)
        buttonsStackView.addArrangedSubview(snoozeButton)
        buttonsStackView.addArrangedSubview(deleteButton)
        
        // Add call button separately for better layout control
        containerView.addSubview(callButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            // Name label
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: snoozeBadge.leadingAnchor, constant: -8),
            
            // Snooze badge
            snoozeBadge.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            snoozeBadge.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            snoozeBadge.widthAnchor.constraint(equalToConstant: 60),
            snoozeBadge.heightAnchor.constraint(equalToConstant: 20),
            
            // Phone label
            phoneLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            phoneLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            phoneLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Time label
            timeLabel.topAnchor.constraint(equalTo: phoneLabel.bottomAnchor, constant: 4),
            timeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            timeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Next call label
            nextCallLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 4),
            nextCallLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            nextCallLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Call button
            callButton.topAnchor.constraint(equalTo: nextCallLabel.bottomAnchor, constant: 12),
            callButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            callButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            callButton.heightAnchor.constraint(equalToConstant: 36),
            
            // Buttons stack view
            buttonsStackView.topAnchor.constraint(equalTo: callButton.bottomAnchor, constant: 8),
            buttonsStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            buttonsStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            buttonsStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            buttonsStackView.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    private func setupActions() {
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        snoozeButton.addTarget(self, action: #selector(snoozeButtonTapped), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        callButton.addTarget(self, action: #selector(callButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Configuration
    
    func configure(with setup: CallSetup) {
        self.callSetup = setup
        
        nameLabel.text = setup.name
        phoneLabel.text = setup.phoneNumber
        
        // Format time and weekdays
        let timeString = setup.timeString
        let weekdaysString = formatWeekdays(setup.weekdaysArray)
        timeLabel.text = "\(timeString) • \(weekdaysString)"
        
        // Next call information
        if let nextCall = setup.nextCallDate {
            nextCallLabel.text = "Next call: \(formatNextCallDate(nextCall))"
            nextCallLabel.isHidden = false
        } else {
            nextCallLabel.isHidden = true
        }
        
        // Snooze state
        let isSnoozed = setup.isCurrentlySnoozed
        snoozeBadge.isHidden = !isSnoozed
        
        // Update snooze button
        updateSnoozeButton(isSnoozed: isSnoozed)
        
        // Update container appearance based on snooze state
        containerView.alpha = isSnoozed ? 0.7 : 1.0
    }
    
    private func updateSnoozeButton(isSnoozed: Bool) {
        if isSnoozed {
            snoozeButton.setTitle("Unsnooze", for: .normal)
            snoozeButton.backgroundColor = .systemBlue
            snoozeButton.setTitleColor(.white, for: .normal)
            snoozeButton.layer.borderColor = UIColor.systemBlue.cgColor
        } else {
            snoozeButton.setTitle("Snooze", for: .normal)
            snoozeButton.backgroundColor = .systemBackground
            snoozeButton.setTitleColor(.systemOrange, for: .normal)
            snoozeButton.layer.borderColor = UIColor.systemOrange.cgColor
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatWeekdays(_ weekdays: [Int]) -> String {
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let sortedDays = weekdays.sorted()
        return sortedDays.map { dayNames[$0] }.joined(separator: ", ")
    }
    
    private func formatNextCallDate(_ date: Date) -> String {
        let calendar = Calendar.current
        _ = Date()
        
        if calendar.isDateInToday(date) {
            return "Today at \(DateFormatter.timeFormatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow at \(DateFormatter.timeFormatter.string(from: date))"
        } else {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"
            return "\(dayFormatter.string(from: date)) at \(DateFormatter.timeFormatter.string(from: date))"
        }
    }
    
    // MARK: - Actions
    
    @objc private func editButtonTapped() {
        guard let setup = callSetup else { return }
        delegate?.didTapEdit(for: setup)
    }
    
    @objc private func snoozeButtonTapped() {
        guard let setup = callSetup else { return }
        delegate?.didTapSnooze(for: setup)
    }
    
    @objc private func deleteButtonTapped() {
        guard let setup = callSetup else { return }
        delegate?.didTapDelete(for: setup)
    }
    
    @objc private func callButtonTapped() {
        guard let setup = callSetup else { return }
        delegate?.didTapCall(for: setup)
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        phoneLabel.text = nil
        timeLabel.text = nil
        nextCallLabel.text = nil
        nextCallLabel.isHidden = false
        snoozeBadge.isHidden = true
        containerView.alpha = 1.0
        callSetup = nil
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}
