//
//  BVNotesViewModel.swift
//  Speedoc Clinical Notes
//
//  BV Notes - State management and business logic
//

import SwiftUI
import Combine

@MainActor
class BVNotesViewModel: ObservableObject {
    @Published var currentState: BVState
    @Published var globalSettings: GlobalVaccineSettings
    @Published var validationErrors: [BVValidationError] = []
    
    private let settingsFileName = "bv_settings.json"
    private let stateFilePrefix = "bv_state_"
    
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    init() {
        // Load global settings
        self.globalSettings = Self.loadGlobalSettings() ?? GlobalVaccineSettings.createDefaults()
        
        // Load last used milestone or default to 12 months
        if let lastMilestone = UserDefaults.standard.string(forKey: "bv_last_milestone"),
           let milestone = Milestone(rawValue: lastMilestone) {
            self.currentState = Self.loadState(for: milestone) ?? BVState(milestone: milestone)
        } else {
            self.currentState = BVState(milestone: .m12)
        }
        
        // Initialize selections for current milestone
        if currentState.selections.isEmpty {
            initializeSelections(for: currentState.milestone)
        }
    }
    
    // MARK: - Milestone Management
    
    func selectMilestone(_ milestone: Milestone) {
        // Save current state before switching
        saveCurrentState()
        
        // Load or create state for new milestone
        if let savedState = Self.loadState(for: milestone) {
            currentState = savedState
        } else {
            currentState = BVState(milestone: milestone)
        }
        
        // Always reset to defaults when a new milestone is selected
        initializeSelections(for: milestone)
        currentState.dateOfVisit = Date()
        currentState.cds = .yes
        currentState.additionalNotes = currentState.additionalNotes // keep template-applied notes if any
        currentState.paymentMode = nil
        
        // Update last used milestone
        UserDefaults.standard.set(milestone.rawValue, forKey: "bv_last_milestone")
        
        // Validate and persist
        validate()
        saveCurrentState()
    }
    
    func initializeSelections(for milestone: Milestone) {
        let applicableVaccines = milestone.applicableVaccines
        let template = globalSettings.milestoneTemplates[milestone.rawValue] ?? MilestoneTemplate()
        
        currentState.selections = applicableVaccines.map { vaccine in
            let isSelected = template.defaultSelections[vaccine.rawValue] ?? !milestone.optionalVaccines.contains(vaccine)
            let lotNumber = globalSettings.lotNumbers[vaccine.rawValue] ?? ""
            let dosageSequence = template.defaultDosages[vaccine.rawValue] ?? "Dose 1"
            
            return VaccineSelection(
                vaccine: vaccine,
                selected: isSelected,
                lotNumber: lotNumber,
                dosageSequence: dosageSequence
            )
        }
        
        // Apply follow-up plan to additional notes if available
        if !template.followUpPlan.isEmpty {
            currentState.additionalNotes = template.followUpPlan
        } else {
            currentState.additionalNotes = ""
        }
        
        // Clear payment mode when initializing
        currentState.paymentMode = nil
    }
    
    // MARK: - Vaccine Selection Management
    
    func toggleVaccineSelection(vaccine: Vaccine, isSelected: Bool) {
        guard let index = currentState.selections.firstIndex(where: { $0.vaccine == vaccine }) else {
            return
        }
        
        currentState.selections[index].selected = isSelected
        
        // Handle PCV mutual exclusion
        if isSelected && vaccine.isPCVVaccine() {
            // Deselect other PCVs
            for (idx, selection) in currentState.selections.enumerated() {
                if selection.vaccine.isPCVVaccine() && selection.vaccine != vaccine {
                    currentState.selections[idx].selected = false
                }
            }
        }
        
        validate()
        saveCurrentState()
    }
    
    func updateLotNumber(for vaccine: Vaccine, lotNumber: String) {
        guard let index = currentState.selections.firstIndex(where: { $0.vaccine == vaccine }) else {
            return
        }
        
        currentState.selections[index].lotNumber = lotNumber
        saveCurrentState()
    }
    
    func updateDosageSequence(for vaccine: Vaccine, sequence: String) {
        guard let index = currentState.selections.firstIndex(where: { $0.vaccine == vaccine }) else {
            return
        }
        
        currentState.selections[index].dosageSequence = sequence
        saveCurrentState()
    }
    
    // MARK: - Additional Actions
    
    func updateCDS(_ cds: CDS) {
        currentState.cds = cds
        saveCurrentState()
    }
    
    func updatePaymentMode(_ mode: PaymentMode?) {
        currentState.paymentMode = mode
        validate()
        saveCurrentState()
    }
    
    func updateAdditionalNotes(_ notes: String) {
        currentState.additionalNotes = notes
        saveCurrentState()
    }
    
    func appendSideEffectsNote() {
        // Updated standard side effects note (two lines)
        let sideEffectsText = """
        Explained side effects of all vaccinations.
        Tolerated vaccination well
        """
        
        if currentState.additionalNotes.isEmpty {
            currentState.additionalNotes = sideEffectsText
        } else if !currentState.additionalNotes.contains(sideEffectsText) {
            currentState.additionalNotes += "\n\n" + sideEffectsText
        }
        
        saveCurrentState()
    }
    
    func resetToDefaults() {
        initializeSelections(for: currentState.milestone)
        currentState.dateOfVisit = Date()
        currentState.cds = .yes
        validate()
        saveCurrentState()
    }
    
    // MARK: - Validation
    
    func validate() {
        validationErrors = validateSelections(currentState)
    }
    
    var isValid: Bool {
        validationErrors.isEmpty
    }
    
    // MARK: - Notes Generation
    
    func generateClinicalNote() -> String {
        return composeClinicalNote(for: currentState)
    }
    
    var requiresPaymentMode: Bool {
        let selectedVaccines = currentState.selections.filter { $0.selected }
        return selectedVaccines.contains { selection in
            currentState.milestone.vaccinesRequiringPayment.contains(selection.vaccine)
        }
    }
    
    // MARK: - Settings Management
    
    func saveGlobalSettings() {
        let settingsURL = documentsDirectory.appendingPathComponent(settingsFileName)
        
        if let data = try? JSONEncoder().encode(globalSettings) {
            try? data.write(to: settingsURL)
        }
    }
    
    static func loadGlobalSettings() -> GlobalVaccineSettings? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let settingsURL = documentsDirectory.appendingPathComponent("bv_settings.json")
        
        guard let data = try? Data(contentsOf: settingsURL),
              let settings = try? JSONDecoder().decode(GlobalVaccineSettings.self, from: data) else {
            return nil
        }
        
        return settings
    }
    
    func restoreDefaultSettings() {
        globalSettings = GlobalVaccineSettings.createDefaults()
        saveGlobalSettings()
        
        // Re-initialize current milestone with new defaults
        initializeSelections(for: currentState.milestone)
    }
    
    func updateLotNumberInSettings(for vaccine: Vaccine, lotNumber: String) {
        globalSettings.lotNumbers[vaccine.rawValue] = lotNumber
        saveGlobalSettings()
    }
    
    func updateMilestoneTemplate(_ milestone: Milestone, template: MilestoneTemplate) {
        globalSettings.milestoneTemplates[milestone.rawValue] = template
        saveGlobalSettings()
    }
    
    // MARK: - State Persistence
    
    func saveCurrentState() {
        let stateURL = documentsDirectory.appendingPathComponent("\(stateFilePrefix)\(currentState.milestone.rawValue).json")
        
        if let data = try? JSONEncoder().encode(currentState) {
            try? data.write(to: stateURL)
        }
    }
    
    static func loadState(for milestone: Milestone) -> BVState? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let stateURL = documentsDirectory.appendingPathComponent("bv_state_\(milestone.rawValue).json")
        
        guard let data = try? Data(contentsOf: stateURL),
              let state = try? JSONDecoder().decode(BVState.self, from: data) else {
            return nil
        }
        
        return state
    }
}

