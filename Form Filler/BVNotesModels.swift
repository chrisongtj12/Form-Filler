//
//  Models.swift
//  Speedoc Clinical Notes
//
//  BV Notes (Baby Vaccination Notes) - Data Models
//

import Foundation

// MARK: - Milestone

enum Milestone: String, CaseIterable, Codable, Identifiable {
    case m2 = "2 Month"
    case m4 = "4 Month"
    case m6 = "6 Month"
    case m12 = "12 Month"
    case m15 = "15 Month"
    case m18 = "18 Month"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    /// Returns the applicable vaccines for this milestone
    var applicableVaccines: [Vaccine] {
        switch self {
        case .m2:
            return [.hexaxim, .rotarix, .pcv20]
        case .m4:
            return [.pentaxim, .pcv13, .pcv15, .pcv20, .rotarix]
        case .m6:
            return [.hexaxim, .pcv13, .pcv15, .pcv20]
        case .m12:
            return [.mmr, .varicella, .pcv13, .pcv15, .pcv20]
        case .m15:
            return [.mmr, .varicella, .influenza, .havrixJr]
        case .m18:
            return [.pentaxim, .influenza, .havrixJr]
        }
    }
    
    /// Returns which vaccines are optional for this milestone
    var optionalVaccines: Set<Vaccine> {
        switch self {
        case .m2:
            return [.rotarix, .pcv20]
        case .m4:
            return [.pcv15, .pcv20, .rotarix]
        case .m6:
            return [.pcv15, .pcv20]
        case .m12:
            return [.pcv15, .pcv20]
        case .m15:
            return [.influenza, .havrixJr]
        case .m18:
            return [.influenza, .havrixJr]
        }
    }
    
    /// Returns which vaccines require payment mode (optional vaccines minus Influenza)
    var vaccinesRequiringPayment: Set<Vaccine> {
        optionalVaccines.subtracting([.influenza])
    }
}

// MARK: - Vaccine

enum Vaccine: String, CaseIterable, Codable, Identifiable {
    case hexaxim = "Hexaxim"
    case pentaxim = "Pentaxim"
    case pcv13 = "PCV13"
    case pcv15 = "PCV15"
    case pcv20 = "PCV20"
    case rotarix = "Rotarix"
    case mmr = "MMR"
    case varicella = "Varicella"
    case influenza = "Influenza"
    case havrixJr = "Havrix Jr"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .pcv13:
            return "Prevenar 13"
        case .pcv15:
            return "PCV15"
        case .pcv20:
            return "PCV20"
        case .havrixJr:
            return "Havrix Jr"
        default:
            return rawValue
        }
    }
    
    var shortName: String {
        return displayName
    }
    
    var fullName: String {
        return displayName
    }
    
    /// Key for storing lot numbers
    var lotNumberKey: String {
        switch self {
        case .pcv13:
            return "Prevenar 13 (PCV13)"
        case .pcv15:
            return "PCV15"
        case .pcv20:
            return "PCV20"
        default:
            return rawValue
        }
    }
    
    /// PCV group for mutual exclusion
    static let pcvGroup: Set<Vaccine> = [.pcv13, .pcv15, .pcv20]
    
    func isPCVVaccine() -> Bool {
        Vaccine.pcvGroup.contains(self)
    }
}

// MARK: - VaccineSelection

struct VaccineSelection: Identifiable, Codable, Equatable {
    let id: UUID
    var vaccine: Vaccine
    var selected: Bool
    var lotNumber: String
    var dosageSequence: String // e.g., "Dose 1", "Booster 1"
    
    init(id: UUID = UUID(), vaccine: Vaccine, selected: Bool = false, lotNumber: String = "", dosageSequence: String = "Dose 1") {
        self.id = id
        self.vaccine = vaccine
        self.selected = selected
        self.lotNumber = lotNumber
        self.dosageSequence = dosageSequence
    }
}

// MARK: - CDS (Clinical Decision Support)

enum CDS: String, Codable, CaseIterable, Identifiable {
    case yes = "Yes"
    case no = "No"
    case other = "Other"
    
    var id: String { rawValue }
}

// MARK: - PaymentMode

enum PaymentMode: String, Codable, CaseIterable, Identifiable {
    case paynow = "PayNow"
    case cda = "CDA"
    case credit = "Credit Card"
    
    var id: String { rawValue }
}

// MARK: - BVState

struct BVState: Codable {
    var milestone: Milestone
    var patientName: String
    var patientNRIC: String
    var dateOfVisit: Date
    var selections: [VaccineSelection]
    var cds: CDS
    var additionalNotes: String
    var paymentMode: PaymentMode?
    
    init(milestone: Milestone = .m12, patientName: String = "", patientNRIC: String = "", dateOfVisit: Date = Date(), selections: [VaccineSelection] = [], cds: CDS = .yes, additionalNotes: String = "", paymentMode: PaymentMode? = nil) {
        self.milestone = milestone
        self.patientName = patientName
        self.patientNRIC = patientNRIC
        self.dateOfVisit = dateOfVisit
        self.selections = selections
        self.cds = cds
        self.additionalNotes = additionalNotes
        self.paymentMode = paymentMode
    }
}

// MARK: - MilestoneTemplate

struct MilestoneTemplate: Codable {
    var defaultSelections: [String: Bool]      // Vaccine.rawValue: Bool
    var defaultDosages: [String: String]       // Vaccine.rawValue: "Dose 1", etc.
    var followUpPlan: String
    
    init(defaultSelections: [String: Bool] = [:], defaultDosages: [String: String] = [:], followUpPlan: String = "") {
        self.defaultSelections = defaultSelections
        self.defaultDosages = defaultDosages
        self.followUpPlan = followUpPlan
    }
}

// MARK: - GlobalVaccineSettings

struct GlobalVaccineSettings: Codable {
    var lotNumbers: [String: String]  // Vaccine.rawValue: lot number
    var milestoneTemplates: [String: MilestoneTemplate]  // Milestone.rawValue: template
    
    init(lotNumbers: [String: String] = [:], milestoneTemplates: [String: MilestoneTemplate] = [:]) {
        self.lotNumbers = lotNumbers
        self.milestoneTemplates = milestoneTemplates
    }
    
    /// Create default settings with example lot numbers
    static func createDefaults() -> GlobalVaccineSettings {
        var settings = GlobalVaccineSettings()
        
        // Default lot numbers (from screenshots)
        settings.lotNumbers = [
            Vaccine.hexaxim.rawValue: "X3J474V",
            Vaccine.pentaxim.rawValue: "X3J474V",
            Vaccine.pcv13.rawValue: "MH9555",
            Vaccine.pcv15.rawValue: "PCV15-001",
            Vaccine.pcv20.rawValue: "PCV20-001",
            Vaccine.rotarix.rawValue: "ROT-001",
            Vaccine.mmr.rawValue: "Z006553",
            Vaccine.varicella.rawValue: "Y010272",
            Vaccine.influenza.rawValue: "FLU-001",
            Vaccine.havrixJr.rawValue: "HAV-001"
        ]
        
        // Default milestone templates
        settings.milestoneTemplates = [
            Milestone.m2.rawValue: MilestoneTemplate(
                defaultSelections: [Vaccine.hexaxim.rawValue: true, Vaccine.rotarix.rawValue: false, Vaccine.pcv20.rawValue: false],
                defaultDosages: [Vaccine.hexaxim.rawValue: "Dose 1", Vaccine.rotarix.rawValue: "Dose 1", Vaccine.pcv20.rawValue: "Dose 1"],
                followUpPlan: "Next visit at 4 months for Pentaxim, PCV13, and Rotarix."
            ),
            Milestone.m4.rawValue: MilestoneTemplate(
                defaultSelections: [Vaccine.pentaxim.rawValue: true, Vaccine.pcv13.rawValue: true, Vaccine.pcv15.rawValue: false, Vaccine.pcv20.rawValue: false, Vaccine.rotarix.rawValue: false],
                // PCV20 should be Dose 2 at 4 months
                defaultDosages: [Vaccine.pentaxim.rawValue: "Dose 1", Vaccine.pcv13.rawValue: "Dose 1", Vaccine.pcv15.rawValue: "Dose 1", Vaccine.pcv20.rawValue: "Dose 2", Vaccine.rotarix.rawValue: "Dose 2"],
                followUpPlan: "Next visit at 6 months for Hexaxim and PCV13."
            ),
            Milestone.m6.rawValue: MilestoneTemplate(
                defaultSelections: [Vaccine.hexaxim.rawValue: true, Vaccine.pcv13.rawValue: true, Vaccine.pcv15.rawValue: false, Vaccine.pcv20.rawValue: false],
                // PCV20 should be Dose 3 at 6 months
                defaultDosages: [Vaccine.hexaxim.rawValue: "Dose 2", Vaccine.pcv13.rawValue: "Dose 2", Vaccine.pcv15.rawValue: "Dose 2", Vaccine.pcv20.rawValue: "Dose 3"],
                followUpPlan: "Next visit at 12 months for MMR, Varicella, and PCV13 booster."
            ),
            Milestone.m12.rawValue: MilestoneTemplate(
                defaultSelections: [Vaccine.mmr.rawValue: true, Vaccine.varicella.rawValue: true, Vaccine.pcv13.rawValue: true, Vaccine.pcv15.rawValue: false, Vaccine.pcv20.rawValue: false],
                defaultDosages: [Vaccine.mmr.rawValue: "Dose 1", Vaccine.varicella.rawValue: "Dose 1", Vaccine.pcv13.rawValue: "Booster 1", Vaccine.pcv15.rawValue: "Booster 1", Vaccine.pcv20.rawValue: "Booster 1"],
                followUpPlan: "Next visit at 15 months for nurse visit: MMR dose 2, Varicella dose 2, and Influenza."
            ),
            Milestone.m15.rawValue: MilestoneTemplate(
                defaultSelections: [Vaccine.mmr.rawValue: true, Vaccine.varicella.rawValue: true, Vaccine.influenza.rawValue: false, Vaccine.havrixJr.rawValue: false],
                defaultDosages: [Vaccine.mmr.rawValue: "Dose 2", Vaccine.varicella.rawValue: "Dose 2", Vaccine.influenza.rawValue: "Dose 1", Vaccine.havrixJr.rawValue: "Dose 1"],
                followUpPlan: "Next visit at 18 months for Pentaxim booster."
            ),
            Milestone.m18.rawValue: MilestoneTemplate(
                defaultSelections: [Vaccine.pentaxim.rawValue: true, Vaccine.influenza.rawValue: false, Vaccine.havrixJr.rawValue: false],
                defaultDosages: [Vaccine.pentaxim.rawValue: "Booster 1", Vaccine.influenza.rawValue: "Dose 1", Vaccine.havrixJr.rawValue: "Dose 2"],
                followUpPlan: "Vaccination schedule complete for now. Continue routine check-ups."
            )
        ]
        
        return settings
    }
}

// MARK: - BVValidationError

enum BVValidationError: Error, Identifiable {
    case multiplePCVSelected
    case paymentModeRequired
    case noVaccinesSelected
    
    var id: String {
        switch self {
        case .multiplePCVSelected:
            return "multiplePCV"
        case .paymentModeRequired:
            return "paymentMode"
        case .noVaccinesSelected:
            return "noVaccines"
        }
    }
    
    var message: String {
        switch self {
        case .multiplePCVSelected:
            return "Only one PCV vaccine (PCV13, PCV15, or PCV20) can be selected."
        case .paymentModeRequired:
            return "Payment mode required for optional vaccines (except Influenza)."
        case .noVaccinesSelected:
            return "Please select at least one vaccine."
        }
    }
}

