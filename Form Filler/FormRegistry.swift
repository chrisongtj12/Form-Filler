//
//  FormRegistry.swift
//  Speedoc Clinical Notes
//
//  Descriptors and registry for available forms per institution
//

import Foundation

// MARK: - Form Kind

enum FormKind: String, CaseIterable, Codable {
    case medicalNotes
    case homeVisitRecord
    
    var iconName: String {
        switch self {
        case .medicalNotes:
            return "stethoscope"
        case .homeVisitRecord:
            return "house.fill"
        }
    }
}

// MARK: - Form Descriptor

struct FormDescriptor: Identifiable, Codable, Equatable {
    let id: UUID
    let institutionType: InstitutionType
    let kind: FormKind
    let title: String
    let pageCount: Int
    let exportFilenameFormat: String
    
    init(
        id: UUID = UUID(),
        institutionType: InstitutionType,
        kind: FormKind,
        title: String,
        pageCount: Int,
        exportFilenameFormat: String
    ) {
        self.id = id
        self.institutionType = institutionType
        self.kind = kind
        self.title = title
        self.pageCount = pageCount
        self.exportFilenameFormat = exportFilenameFormat
    }
}

// MARK: - Registry

final class FormRegistry {
    static let shared = FormRegistry()
    private init() {}
    
    private lazy var allForms: [FormDescriptor] = {
        var list: [FormDescriptor] = []
        
        // Active Global
        list.append(
            FormDescriptor(
                institutionType: .activeGlobal,
                kind: .medicalNotes,
                title: "Medical Notes",
                pageCount: 2,
                exportFilenameFormat: "{PATIENT_NAME} Notes.pdf"
            )
        )
        list.append(
            FormDescriptor(
                institutionType: .activeGlobal,
                kind: .homeVisitRecord,
                title: "Home Visit Record",
                pageCount: 1,
                exportFilenameFormat: "{PATIENT_NAME} HV.pdf"
            )
        )
        
        // Lentor
        list.append(
            FormDescriptor(
                institutionType: .lentor,
                kind: .medicalNotes,
                title: "Chronic Medical Review",
                pageCount: 3,
                exportFilenameFormat: "{PATIENT_NAME} Lentor Notes.pdf"
            )
        )
        list.append(
            FormDescriptor(
                institutionType: .lentor,
                kind: .homeVisitRecord,
                title: "Service Attendance Record",
                pageCount: 1,
                exportFilenameFormat: "{PATIENT_NAME} Lentor HV.pdf"
            )
        )
        
        return list
    }()
    
    func forms(for institution: Institution) -> [FormDescriptor] {
        guard let type = institution.institutionType else { return [] }
        return allForms.filter { $0.institutionType == type }
    }
    
    func descriptor(institution: Institution, kind: FormKind) -> FormDescriptor? {
        guard let type = institution.institutionType else { return nil }
        return allForms.first { $0.institutionType == type && $0.kind == kind }
    }
}
