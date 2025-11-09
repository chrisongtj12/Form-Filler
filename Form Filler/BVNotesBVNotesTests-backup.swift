//
//  BVNotesTests.swift
//  Speedoc Clinical Notes
//
//  Unit tests for BV Notes functionality
//

import XCTest
import Foundation

// MARK: - Validation Tests

final class BVNotesValidationTests: XCTestCase {
    
    func testNoVaccinesSelected() async throws {
        var state = BVState(milestone: .m12)
        state.selections = [
            VaccineSelection(vaccine: .mmr, selected: false, lotNumber: "", dosageSequence: "Dose 1"),
            VaccineSelection(vaccine: .varicella, selected: false, lotNumber: "", dosageSequence: "Dose 1")
        ]
        
        let errors = validateSelections(state)
        XCTAssertTrue(errors.contains { $0 is BVValidationError && $0.id == "noVaccines" })
    }
    
    func testMultiplePCVSelected() async throws {
        var state = BVState(milestone: .m12)
        state.selections = [
            VaccineSelection(vaccine: .pcv13, selected: true, lotNumber: "LOT1", dosageSequence: "Booster 1"),
            VaccineSelection(vaccine: .pcv15, selected: true, lotNumber: "LOT2", dosageSequence: "Booster 1"),
            VaccineSelection(vaccine: .mmr, selected: true, lotNumber: "LOT3", dosageSequence: "Dose 1")
        ]
        
        let errors = validateSelections(state)
        XCTAssertTrue(errors.contains { $0.id == "multiplePCV" })
    }
    
    func testSinglePCVSelected() async throws {
        var state = BVState(milestone: .m12)
        state.selections = [
            VaccineSelection(vaccine: .pcv13, selected: true, lotNumber: "LOT1", dosageSequence: "Booster 1"),
            VaccineSelection(vaccine: .pcv15, selected: false, lotNumber: "", dosageSequence: "Booster 1"),
            VaccineSelection(vaccine: .mmr, selected: true, lotNumber: "LOT2", dosageSequence: "Dose 1")
        ]
        
        let errors = validateSelections(state)
        XCTAssertFalse(errors.contains { $0.id == "multiplePCV" })
    }
    
    func testOptionalVaccineRequiresPayment() async throws {
        var state = BVState(milestone: .m15)
        state.selections = [
            VaccineSelection(vaccine: .mmr, selected: true, lotNumber: "LOT1", dosageSequence: "Dose 2"),
            VaccineSelection(vaccine: .havrixJr, selected: true, lotNumber: "LOT2", dosageSequence: "Dose 1")
        ]
        state.paymentMode = nil
        
        let errors = validateSelections(state)
        XCTAssertTrue(errors.contains { $0.id == "paymentMode" })
    }
    
    func testOptionalVaccineWithPayment() async throws {
        var state = BVState(milestone: .m15)
        state.selections = [
            VaccineSelection(vaccine: .mmr, selected: true, lotNumber: "LOT1", dosageSequence: "Dose 2"),
            VaccineSelection(vaccine: .havrixJr, selected: true, lotNumber: "LOT2", dosageSequence: "Dose 1")
        ]
        state.paymentMode = .paynow
        
        let errors = validateSelections(state)
        XCTAssertFalse(errors.contains { $0.id == "paymentMode" })
    }
    
    func testInfluenzaDoesNotRequirePayment() async throws {
        var state = BVState(milestone: .m15)
        state.selections = [
            VaccineSelection(vaccine: .mmr, selected: true, lotNumber: "LOT1", dosageSequence: "Dose 2"),
            VaccineSelection(vaccine: .influenza, selected: true, lotNumber: "LOT2", dosageSequence: "Dose 1")
        ]
        state.paymentMode = nil
        
        let errors = validateSelections(state)
        XCTAssertFalse(errors.contains { $0.id == "paymentMode" })
    }
}

// MARK: - Notes Composition Tests

final class BVNotesCompositionTests: XCTestCase {
    
    func testComposeNote12Month() async throws {
        var state = BVState(milestone: .m12)
        let calendar = Calendar.current
        state.dateOfVisit = calendar.date(from: DateComponents(year: 2025, month: 11, day: 9))!
        state.selections = [
            VaccineSelection(vaccine: .mmr, selected: true, lotNumber: "Z006553", dosageSequence: "Dose 1"),
            VaccineSelection(vaccine: .varicella, selected: true, lotNumber: "Y010272", dosageSequence: "Dose 1"),
            VaccineSelection(vaccine: .pcv13, selected: true, lotNumber: "MH9555", dosageSequence: "Booster 1")
        ]
        state.cds = .yes
        state.additionalNotes = "No immediate adverse events observed post-vaccination."
        
        let note = composeClinicalNote(for: state)
        
        XCTAssertTrue(note.contains("Date of Visit: 09/11/2025"))
        XCTAssertTrue(note.contains("Vaccine Administration Documentation"))
        XCTAssertTrue(note.contains("MMR"))
        XCTAssertTrue(note.contains("Varicella"))
        XCTAssertTrue(note.contains("Prevenar 13"))
        XCTAssertTrue(note.contains("Z006553"))
        XCTAssertTrue(note.contains("Y010272"))
        XCTAssertTrue(note.contains("MH9555"))
        XCTAssertTrue(note.contains("CDS Done by you during this visit?: Yes"))
        XCTAssertTrue(note.contains("No immediate adverse events observed post-vaccination."))
    }
    
    func testComposeNoteWithPayment() async throws {
        var state = BVState(milestone: .m15)
        state.dateOfVisit = Date()
        state.selections = [
            VaccineSelection(vaccine: .mmr, selected: true, lotNumber: "LOT1", dosageSequence: "Dose 2"),
            VaccineSelection(vaccine: .havrixJr, selected: true, lotNumber: "HAV-001", dosageSequence: "Dose 1")
        ]
        state.cds = .yes
        state.paymentMode = .paynow
        
        let note = composeClinicalNote(for: state)
        
        XCTAssertTrue(note.contains("Payment Mode (for optional vaccines): PayNow"))
    }
    
    func testComposeNoteWithoutPayment() async throws {
        var state = BVState(milestone: .m12)
        state.dateOfVisit = Date()
        state.selections = [
            VaccineSelection(vaccine: .mmr, selected: true, lotNumber: "LOT1", dosageSequence: "Dose 1"),
            VaccineSelection(vaccine: .varicella, selected: true, lotNumber: "LOT2", dosageSequence: "Dose 1")
        ]
        state.cds = .yes
        
        let note = composeClinicalNote(for: state)
        
        XCTAssertFalse(note.contains("Payment Mode"))
    }
    
    func testNoteContainsSelectedVaccinesOnly() async throws {
        var state = BVState(milestone: .m12)
        state.dateOfVisit = Date()
        state.selections = [
            VaccineSelection(vaccine: .mmr, selected: true, lotNumber: "LOT1", dosageSequence: "Dose 1"),
            VaccineSelection(vaccine: .varicella, selected: false, lotNumber: "LOT2", dosageSequence: "Dose 1"),
            VaccineSelection(vaccine: .pcv13, selected: true, lotNumber: "LOT3", dosageSequence: "Booster 1")
        ]
        state.cds = .yes
        
        let note = composeClinicalNote(for: state)
        
        XCTAssertTrue(note.contains("MMR"))
        XCTAssertFalse(note.contains("Varicella"))
        XCTAssertTrue(note.contains("Prevenar 13"))
    }
}

// MARK: - Milestone Tests

final class MilestoneConfigTests: XCTestCase {
    
    func test2MonthVaccines() async throws {
        let milestone = Milestone.m2
        let vaccines = milestone.applicableVaccines
        
        XCTAssertTrue(vaccines.contains(.hexaxim))
        XCTAssertTrue(vaccines.contains(.rotarix))
        XCTAssertTrue(vaccines.contains(.pcv20))
        XCTAssertEqual(vaccines.count, 3)
    }
    
    func test4MonthVaccines() async throws {
        let milestone = Milestone.m4
        let vaccines = milestone.applicableVaccines
        
        XCTAssertTrue(vaccines.contains(.pentaxim))
        XCTAssertTrue(vaccines.contains(.pcv13))
        XCTAssertTrue(vaccines.contains(.pcv15))
        XCTAssertTrue(vaccines.contains(.pcv20))
        XCTAssertTrue(vaccines.contains(.rotarix))
        XCTAssertEqual(vaccines.count, 5)
    }
    
    func test12MonthOptionalVaccines() async throws {
        let milestone = Milestone.m12
        let optional = milestone.optionalVaccines
        
        XCTAssertTrue(optional.contains(.pcv15))
        XCTAssertTrue(optional.contains(.pcv20))
        XCTAssertFalse(optional.contains(.mmr))
        XCTAssertFalse(optional.contains(.varicella))
        XCTAssertFalse(optional.contains(.pcv13))
    }
    
    func test15MonthPaymentRequirement() async throws {
        let milestone = Milestone.m15
        let requiresPayment = milestone.vaccinesRequiringPayment
        
        XCTAssertTrue(requiresPayment.contains(.havrixJr))
        XCTAssertFalse(requiresPayment.contains(.influenza))
        XCTAssertFalse(requiresPayment.contains(.mmr))
        XCTAssertFalse(requiresPayment.contains(.varicella))
    }
}

// MARK: - Vaccine Tests

final class VaccineConfigTests: XCTestCase {
    
    func testPCVIdentification() async throws {
        XCTAssertTrue(Vaccine.pcv13.isPCVVaccine())
        XCTAssertTrue(Vaccine.pcv15.isPCVVaccine())
        XCTAssertTrue(Vaccine.pcv20.isPCVVaccine())
        XCTAssertFalse(Vaccine.mmr.isPCVVaccine())
        XCTAssertFalse(Vaccine.hexaxim.isPCVVaccine())
    }
    
    func testVaccineDisplayNames() async throws {
        XCTAssertEqual(Vaccine.pcv13.displayName, "Prevenar 13")
        XCTAssertEqual(Vaccine.pcv15.displayName, "PCV15")
        XCTAssertEqual(Vaccine.pcv20.displayName, "PCV20")
        XCTAssertEqual(Vaccine.havrixJr.displayName, "Havrix Jr")
        XCTAssertEqual(Vaccine.mmr.displayName, "MMR")
    }
}

// MARK: - Settings Tests

final class GlobalSettingsTests: XCTestCase {
    
    func testDefaultSettings() async throws {
        let settings = GlobalVaccineSettings.createDefaults()
        
        XCTAssertNotNil(settings.lotNumbers[Vaccine.hexaxim.rawValue])
        XCTAssertEqual(settings.lotNumbers[Vaccine.mmr.rawValue], "Z006553")
        XCTAssertEqual(settings.lotNumbers[Vaccine.varicella.rawValue], "Y010272")
        XCTAssertEqual(settings.lotNumbers[Vaccine.pcv13.rawValue], "MH9555")
    }
    
    func testDefaultMilestoneTemplates() async throws {
        let settings = GlobalVaccineSettings.createDefaults()
        
        XCTAssertNotNil(settings.milestoneTemplates[Milestone.m2.rawValue])
        XCTAssertNotNil(settings.milestoneTemplates[Milestone.m12.rawValue])
        XCTAssertNotNil(settings.milestoneTemplates[Milestone.m18.rawValue])
    }
    
    func test12MonthTemplate() async throws {
        let settings = GlobalVaccineSettings.createDefaults()
        let template = settings.milestoneTemplates[Milestone.m12.rawValue]
        
        XCTAssertNotNil(template)
        XCTAssertEqual(template?.defaultSelections[Vaccine.mmr.rawValue], true)
        XCTAssertEqual(template?.defaultSelections[Vaccine.varicella.rawValue], true)
        XCTAssertEqual(template?.defaultSelections[Vaccine.pcv13.rawValue], true)
        XCTAssertTrue(template?.followUpPlan.contains("15 months") == true)
    }
}
