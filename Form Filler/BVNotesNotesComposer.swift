//
//  NotesComposer.swift
//  Speedoc Clinical Notes
//
//  BV Notes - Pure functions for generating Avixo-ready clinical notes
//

import Foundation

/// Validates BV state and returns any errors
func validateSelections(_ state: BVState) -> [BVValidationError] {
    var errors: [BVValidationError] = []
    
    let selectedVaccines = state.selections.filter { $0.selected }
    
    // Check if no vaccines selected
    if selectedVaccines.isEmpty {
        errors.append(.noVaccinesSelected)
    }
    
    // Check PCV rule: only one PCV can be selected
    let selectedPCVs = selectedVaccines.filter { $0.vaccine.isPCVVaccine() }
    if selectedPCVs.count > 1 {
        errors.append(.multiplePCVSelected)
    }
    
    // Check payment mode requirement
    let requiresPayment = selectedVaccines.contains { selection in
        state.milestone.vaccinesRequiringPayment.contains(selection.vaccine)
    }
    
    if requiresPayment && state.paymentMode == nil {
        errors.append(.paymentModeRequired)
    }
    
    return errors
}

/// Generates the complete clinical note text for Avixo
func composeClinicalNote(for state: BVState) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd/MM/yyyy"
    let dateString = dateFormatter.string(from: state.dateOfVisit)
    
    var output = ""
    
    // Header
    output += "Date of Visit: \(dateString)\n\n"
    output += "Vaccine Administration Documentation\n\n"
    
    // Table header
    let col1Width = 25
    let col2Width = 20
    let col3Width = 15
    
    output += padRight("Vaccine Name", width: col1Width)
    output += padRight("Dosage Sequence", width: col2Width)
    output += padRight("Lot Number", width: col3Width)
    output += "\n"
    output += String(repeating: "-", count: col1Width + col2Width + col3Width) + "\n"
    
    // Table rows for selected vaccines
    let selectedVaccines = state.selections.filter { $0.selected }.sorted { $0.vaccine.rawValue < $1.vaccine.rawValue }
    
    for selection in selectedVaccines {
        output += padRight(selection.vaccine.displayName, width: col1Width)
        output += padRight(selection.dosageSequence, width: col2Width)
        output += padRight(selection.lotNumber.isEmpty ? "N/A" : selection.lotNumber, width: col3Width)
        output += "\n"
    }
    
    output += "\n"
    
    // CDS
    output += "CDS Done by you during this visit?: \(state.cds.rawValue)\n\n"
    
    // Payment mode (if applicable)
    if let paymentMode = state.paymentMode {
        output += "Payment Mode (for optional vaccines): \(paymentMode.rawValue)\n\n"
    }
    
    // Additional Notes
    if !state.additionalNotes.isEmpty {
        output += "Additional Notes:\n"
        output += state.additionalNotes
        output += "\n"
    }
    
    return output
}

// MARK: - Helper Functions

private func padRight(_ text: String, width: Int) -> String {
    if text.count >= width {
        return text
    }
    return text + String(repeating: " ", count: width - text.count)
}

// MARK: - Unit Test Helpers

#if DEBUG
/// Test data for preview/testing
struct BVNotesTestData {
    static var sampleState12Month: BVState {
        var state = BVState(milestone: .m12)
        state.dateOfVisit = Date()
        state.selections = [
            VaccineSelection(vaccine: .mmr, selected: true, lotNumber: "Z006553", dosageSequence: "Dose 1"),
            VaccineSelection(vaccine: .varicella, selected: true, lotNumber: "Y010272", dosageSequence: "Dose 1"),
            VaccineSelection(vaccine: .pcv13, selected: true, lotNumber: "MH9555", dosageSequence: "Booster 1"),
            VaccineSelection(vaccine: .pcv15, selected: false, lotNumber: "", dosageSequence: "Booster 1"),
            VaccineSelection(vaccine: .pcv20, selected: false, lotNumber: "", dosageSequence: "Booster 1")
        ]
        state.cds = .yes
        state.additionalNotes = "No immediate adverse events observed post-vaccination.\n\nNext visit at 15 months for nurse visit: MMR dose 2, Varicella dose 2, and Influenza."
        return state
    }
    
    static var sampleState15Month: BVState {
        var state = BVState(milestone: .m15)
        state.dateOfVisit = Date()
        state.selections = [
            VaccineSelection(vaccine: .mmr, selected: true, lotNumber: "Z006553", dosageSequence: "Dose 2"),
            VaccineSelection(vaccine: .varicella, selected: true, lotNumber: "Y010272", dosageSequence: "Dose 2"),
            VaccineSelection(vaccine: .influenza, selected: true, lotNumber: "FLU-001", dosageSequence: "Dose 1"),
            VaccineSelection(vaccine: .havrixJr, selected: true, lotNumber: "HAV-001", dosageSequence: "Dose 1")
        ]
        state.cds = .yes
        state.paymentMode = .paynow // Required for Havrix Jr
        state.additionalNotes = "No immediate adverse events observed post-vaccination.\n\nNext visit at 18 months for Pentaxim booster."
        return state
    }
}
#endif
