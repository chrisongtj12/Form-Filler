//
//  Institution.swift
//  Speedoc Clinical Notes
//
//  Multi-institution support - data models
//

import Foundation
import UIKit

// MARK: - Institution

enum Institution: String, CaseIterable, Codable {
    case activeGlobal = "Active Global"
    case lentor = "Lentor"
    
    var displayName: String { rawValue }
    
    var subtitle: String {
        switch self {
        case .activeGlobal:
            return "Medical Notes, HV Record"
        case .lentor:
            return "Medical Notes, HV Record"
        }
    }
    
    var iconName: String {
        switch self {
        case .activeGlobal:
            return "building.2.fill"
        case .lentor:
            return "building.fill"
        }
    }
}

// MARK: - Form Kind

enum FormKind: String, CaseIterable, Codable {
    case medicalNotes = "Medical Notes"
    case homeVisitRecord = "Home Visit Record"
    
    var displayName: String { rawValue }
    
    var iconName: String {
        switch self {
        case .medicalNotes:
            return "heart.text.square.fill"
        case .homeVisitRecord:
            return "house.fill"
        }
    }
}

// MARK: - Form Descriptor

struct FormDescriptor: Identifiable {
    let id = UUID()
    let institution: Institution
    let kind: FormKind
    let title: String
    let pdfAssetNames: [String] // Multiple pages supported
    let exportFilenameFormat: String // e.g. "{PATIENT_NAME} Lentor Notes.pdf"
    let pageCount: Int
    
    var fullTitle: String {
        "\(institution.displayName) - \(kind.displayName)"
    }
}

// MARK: - Form Registry

class FormRegistry {
    static let shared = FormRegistry()
    
    private init() {}
    
    func allForms() -> [FormDescriptor] {
        return activeGlobalForms() + lentorForms()
    }
    
    func forms(for institution: Institution) -> [FormDescriptor] {
        switch institution {
        case .activeGlobal:
            return activeGlobalForms()
        case .lentor:
            return lentorForms()
        }
    }
    
    func descriptor(institution: Institution, kind: FormKind) -> FormDescriptor? {
        return forms(for: institution).first { $0.kind == kind }
    }
    
    // MARK: - Active Global Forms
    
    private func activeGlobalForms() -> [FormDescriptor] {
        return [
            FormDescriptor(
                institution: .activeGlobal,
                kind: .medicalNotes,
                title: "Medical Notes",
                pdfAssetNames: ["AG_MedicalNotes_p1", "AG_MedicalNotes_p2"],
                exportFilenameFormat: "{PATIENT_NAME} Notes.pdf",
                pageCount: 2
            ),
            FormDescriptor(
                institution: .activeGlobal,
                kind: .homeVisitRecord,
                title: "Home Visit Record",
                pdfAssetNames: ["AG_HomeVisitRecord"],
                exportFilenameFormat: "{PATIENT_NAME} HV.pdf",
                pageCount: 1
            )
        ]
    }
    
    // MARK: - Lentor Forms
    
    private func lentorForms() -> [FormDescriptor] {
        return [
            FormDescriptor(
                institution: .lentor,
                kind: .medicalNotes,
                title: "Chronic Medical Review",
                pdfAssetNames: ["Lentor_MedicalNotes_p1", "Lentor_MedicalNotes_p2", "Lentor_MedicalNotes_p3"],
                exportFilenameFormat: "{PATIENT_NAME} Lentor Notes.pdf",
                pageCount: 3
            ),
            FormDescriptor(
                institution: .lentor,
                kind: .homeVisitRecord,
                title: "Service Attendance Record",
                pdfAssetNames: ["Lentor_HomeVisitRecord"],
                exportFilenameFormat: "{PATIENT_NAME} Lentor HV.pdf",
                pageCount: 1
            )
        ]
    }
}
