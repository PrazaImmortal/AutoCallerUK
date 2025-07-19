//
//  CallSetupViewController.swift
//  HealthcareCallApp
//
//  Create/edit call setup screen
//

import UIKit

class CallSetupViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var hourPicker: UIPickerView!
    @IBOutlet weak var minutePicker: UIPickerView!
    @IBOutlet weak var weekdaysStackView: UIStackView!
    @IBOutlet weak var retryAttemptsTextField: UITextField!
    @IBOutlet weak var retryDelayTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    // Error labels
    @IBOutlet weak var nameErrorLabel: UILabel!
    @IBOutlet weak var phoneErrorLabel: UILabel!
    @IBOutlet weak var timeErrorLabel: UILabel!
    @IBOutlet weak var weekdaysErrorLabel: UILabel!
    @IBOutlet weak var retryErrorLabel: UILabel!
    
    // MARK: - Properties
    weak var delegate: CallSetupViewControllerDelegate?
    var callSetup: CallSetup?
    
    private let dataManager = DataManager.shared
    private let validationService = ValidationService.shared
    private let callScheduler = CallScheduler.shared
    
    private var selectedWeekdays: Set<Int> = []
    private var weekdayButtons: [UIButton] = []
    
    private let hours = Array(0...23)
    private let minutes = Array(0...59)
    
    private var isEditMode: Bool {
        return callSetup != nil
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTextFields()
        setupPickers()
        setupWeekdayButtons()
        setupValidation()
        populateFields()
        
        // Hide keyboard when tapping outside
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboardManually))
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterKeyboardNotifications()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = isEditMode ? "Edit Call Setup" : "New Call Setup"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelButtonTapped)
        )
        
        view.backgroundColor = .systemGroupedBackground
        contentView.backgroundColor = .clear
        
        // Setup save button
        saveButton.setTitle("Save Setup", for: .normal)
        saveButton.backgroundColor = .systemBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 12
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        
        // Hide error labels initially
        hideAllErrorLabels()
    }
    
    private func setupTextFields() {
        // Name field
        nameTextField.placeholder = "Enter name"
        nameTextField.borderStyle = .roundedRect
        nameTextField.addTarget(self, action: #selector(nameTextChanged), for: .editingChanged)
        
        // Phone field
        phoneTextField.placeholder = "+44 20 7946 0958"
        phoneTextField.keyboardType = .phonePad
        phoneTextField.borderStyle = .roundedRect
        phoneTextField.addTarget(self, action: #selector(phoneTextChanged), for: .editingChanged)
        
        // Retry attempts field
        retryAttemptsTextField.placeholder = "3"
        retryAttemptsTextField.keyboardType = .numberPad
        retryAttemptsTextField.borderStyle = .roundedRect
        retryAttemptsTextField.addTarget(self, action: #selector(retryAttemptsChanged), for: .editingChanged)
        
        // Retry delay field
        retryDelayTextField.placeholder = "5"
        retryDelayTextField.keyboardType = .numberPad
        retryDelayTextField.borderStyle = .roundedRect
        retryDelayTextField.addTarget(self, action: #selector(retryDelayChanged), for: .editingChanged)
        
        // Add toolbar to number pad keyboards
        addToolbarToNumberFields()
    }
    
    private func setupPickers() {
        hourPicker.delegate = self
        hourPicker.dataSource = self
        hourPicker.tag = 0 // Hour picker
        
        minutePicker.delegate = self
        minutePicker.dataSource = self
        minutePicker.tag = 1 // Minute picker
    }
    
    private func setupWeekdayButtons() {
        let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        
        weekdaysStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        weekdayButtons.removeAll()
        
        for (index, day) in weekdays.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(day, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            button.layer.cornerRadius = 8
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.systemBlue.cgColor
            button.backgroundColor = .systemBackground
            button.setTitleColor(.systemBlue, for: .normal)
            button.setTitleColor(.white, for: .selected)
            button.tag = index
            button.addTarget(self, action: #selector(weekdayButtonTapped(_:)), for: .touchUpInside)
            
            // Set button constraints
            button.translatesAutoresizingMaskIntoConstraints = false
            button.heightAnchor.constraint(equalToConstant: 40).isActive = true
            button.widthAnchor.constraint(equalToConstant: 40).isActive = true
            
            weekdaysStackView.addArrangedSubview(button)
            weekdayButtons.append(button)
        }
    }
    
    private func setupValidation() {
        // Real-time validation will be handled in text change methods
    }
    
    private func addToolbarToNumberFields() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(hideKeyboardManually))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolbar.items = [flexSpace, doneButton]
        
        retryAttemptsTextField.inputAccessoryView = toolbar
        retryDelayTextField.inputAccessoryView = toolbar
        phoneTextField.inputAccessoryView = toolbar
    }
    
    // MARK: - Data Population
    
    private func populateFields() {
        guard let setup = callSetup else {
            // Set default values for new setup
            retryAttemptsTextField.text = "3"
            retryDelayTextField.text = "5"
            hourPicker.selectRow(9, inComponent: 0, animated: false) // 9 AM
            minutePicker.selectRow(0, inComponent: 0, animated: false) // 00 minutes
            return
        }
        
        // Populate fields with existing setup data
        nameTextField.text = setup.name
        phoneTextField.text = setup.phoneNumber
        retryAttemptsTextField.text = String(setup.retryAttempts)
        retryDelayTextField.text = String(setup.retryDelay)
        
        // Set time pickers
        hourPicker.selectRow(Int(setup.hour), inComponent: 0, animated: false)
        minutePicker.selectRow(Int(setup.minute), inComponent: 0, animated: false)
        
        // Set selected weekdays
        selectedWeekdays = Set(setup.weekdaysArray)
        updateWeekdayButtons()
    }
    
    // MARK: - Actions
    
    @objc private func cancelButtonTapped() {
        delegate?.didCancelCallSetup()
        dismiss(animated: true)
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        saveCallSetup()
    }
    
    @objc private func weekdayButtonTapped(_ sender: UIButton) {
        let weekday = sender.tag
        
        if selectedWeekdays.contains(weekday) {
            selectedWeekdays.remove(weekday)
        } else {
            selectedWeekdays.insert(weekday)
        }
        
        updateWeekdayButtons()
        validateWeekdays()
    }
    
    @objc private func hideKeyboardManually() {
        view.endEditing(true)
    }

    
    // MARK: - Text Field Validation
    
    @objc private func nameTextChanged() {
        validateName()
    }
    
    @objc private func phoneTextChanged() {
        // Format phone number as user types
        if let text = phoneTextField.text {
            let formatted = validationService.formatUKPhoneNumber(text)
            if formatted != text {
                phoneTextField.text = formatted
            }
        }
        validatePhoneNumber()
    }
    
    @objc private func retryAttemptsChanged() {
        validateRetryAttempts()
    }
    
    @objc private func retryDelayChanged() {
        validateRetryDelay()
    }
    
    // MARK: - Validation Methods
    
    private func validateName() {
        let result = validationService.validateName(nameTextField.text ?? "")
        showValidationResult(result, errorLabel: nameErrorLabel)
    }
    
    private func validatePhoneNumber() {
        let result = validationService.validatePhoneNumber(phoneTextField.text ?? "")
        showValidationResult(result, errorLabel: phoneErrorLabel)
    }
    
    private func validateTime() {
        let hour = hourPicker.selectedRow(inComponent: 0)
        let minute = minutePicker.selectedRow(inComponent: 0)
        let result = validationService.validateTime(hour: hour, minute: minute)
        showValidationResult(result, errorLabel: timeErrorLabel)
        
        // Check for conflicts
        checkTimeConflicts()
    }
    
    private func validateWeekdays() {
        let result = validationService.validateWeekdays(Array(selectedWeekdays))
        showValidationResult(result, errorLabel: weekdaysErrorLabel)
    }
    
    private func validateRetryAttempts() {
        let attempts = Int(retryAttemptsTextField.text ?? "") ?? 0
        let result = validationService.validateRetryAttempts(attempts)
        showValidationResult(result, errorLabel: retryErrorLabel)
    }
    
    private func validateRetryDelay() {
        let delay = Int(retryDelayTextField.text ?? "") ?? 0
        let result = validationService.validateRetryDelay(delay)
        showValidationResult(result, errorLabel: retryErrorLabel)
    }
    
    private func checkTimeConflicts() {
        let hour = hourPicker.selectedRow(inComponent: 0)
        let minute = minutePicker.selectedRow(inComponent: 0)
        let weekdays = Array(selectedWeekdays)
        
        let hasConflict = validationService.hasTimeConflict(
            hour: hour,
            minute: minute,
            weekdays: weekdays,
            excludingSetupID: callSetup?.id
        )
        
        if hasConflict {
            timeErrorLabel.text = "This time conflicts with an existing setup"
            timeErrorLabel.isHidden = false
        } else if timeErrorLabel.text?.contains("conflicts") == true {
            timeErrorLabel.isHidden = true
        }
    }
    
    private func showValidationResult(_ result: ValidationService.ValidationResult, errorLabel: UILabel) {
        if result.isValid {
            errorLabel.isHidden = true
        } else {
            errorLabel.text = result.errorMessages.first
            errorLabel.isHidden = false
        }
    }
    
    private func hideAllErrorLabels() {
        [nameErrorLabel, phoneErrorLabel, timeErrorLabel, weekdaysErrorLabel, retryErrorLabel].forEach {
            $0?.isHidden = true
            $0?.textColor = .systemRed
            $0?.font = UIFont.systemFont(ofSize: 12)
        }
    }
    
    // MARK: - UI Updates
    
    private func updateWeekdayButtons() {
        for (index, button) in weekdayButtons.enumerated() {
            let isSelected = selectedWeekdays.contains(index)
            button.isSelected = isSelected
            button.backgroundColor = isSelected ? .systemBlue : .systemBackground
            button.setTitleColor(isSelected ? .white : .systemBlue, for: .normal)
        }
    }
    
    // MARK: - Save Logic
    
    private func saveCallSetup() {
        // Validate all fields
        validateName()
        validatePhoneNumber()
        validateTime()
        validateWeekdays()
        validateRetryAttempts()
        validateRetryDelay()
        
        // Check if all validations pass
        let hasErrors = ![nameErrorLabel, phoneErrorLabel, timeErrorLabel, weekdaysErrorLabel, retryErrorLabel]
            .allSatisfy { $0?.isHidden == true }
        
        if hasErrors {
            showAlert(title: "Validation Error", message: "Please fix the errors before saving.")
            return
        }
        
        // Create or update setup
        let setup = callSetup ?? dataManager.createCallSetup()
        
        setup.name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        setup.phoneNumber = phoneTextField.text ?? ""
        setup.hour = Int16(hourPicker.selectedRow(inComponent: 0))
        setup.minute = Int16(minutePicker.selectedRow(inComponent: 0))
        setup.weekdaysArray = Array(selectedWeekdays)
        setup.retryAttempts = Int16(retryAttemptsTextField.text ?? "3") ?? 3
        setup.retryDelay = Int16(retryDelayTextField.text ?? "5") ?? 5
        
        // Final validation
        let finalValidation = validationService.validateCallSetup(setup)
        if !finalValidation.isValid {
            showAlert(title: "Validation Error", message: finalValidation.errorMessages.joined(separator: "\n"))
            return
        }
        
        // Save to Core Data
        dataManager.save()
        
        // Schedule notifications
        callScheduler.scheduleNotifications(for: setup)
        
        // Notify delegate and dismiss
        delegate?.didSaveCallSetup(setup)
        dismiss(animated: true)
    }
    
    // MARK: - Keyboard Handling
    
    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let keyboardHeight = keyboardFrame.height
        scrollView.contentInset.bottom = keyboardHeight
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight

    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0

    }
    
    // MARK: - Helper Methods
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIPickerViewDataSource

extension CallSetupViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case 0: // Hour picker
            return hours.count
        case 1: // Minute picker
            return minutes.count
        default:
            return 0
        }
    }
}

// MARK: - UIPickerViewDelegate

extension CallSetupViewController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView.tag {
        case 0: // Hour picker
            return String(format: "%02d", hours[row])
        case 1: // Minute picker
            return String(format: "%02d", minutes[row])
        default:
            return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        validateTime()
    }
}
