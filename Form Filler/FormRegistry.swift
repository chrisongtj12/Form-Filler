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
    let institution: Institution
    let kind: FormKind
    let title: String
    let pageCount: Int
    let exportFilenameFormat: String
    
    init(
        id: UUID = UUID(),
        institution: Institution,
        kind: FormKind,
        title: String,
        pageCount: Int,
        exportFilenameFormat: String
    ) {
        self.id = id
        self.institution = institution
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
                institution: .activeGlobal,
                kind: .medicalNotes,
                title: "Medical Notes",
                pageCount: 2,
                exportFilenameFormat: "{PATIENT_NAME} Notes.pdf"
            )
        )
        list.append(
            FormDescriptor(
                institution: .activeGlobal,
                kind: .homeVisitRecord,
                title: "Home Visit Record",
                pageCount: 1,
                exportFilenameFormat: "{PATIENT_NAME} HV.pdf"
            )
        )
        
        // Lentor
        list.append(
            FormDescriptor(
                institution: .lentor,
                kind: .medicalNotes,
                title: "Chronic Medical Review",
                pageCount: 3,
                exportFilenameFormat: "{PATIENT_NAME} Lentor Notes.pdf"
            )
        )
        list.append(
            FormDescriptor(
                institution: .lentor,
                kind: .homeVisitRecord,
                title: "Service Attendance Record",
                pageCount: 1,
                exportFilenameFormat: "{PATIENT_NAME} Lentor HV.pdf"
            )
        )
        
        return list
    }()
    
    func forms(for institution: Institution) -> [FormDescriptor] {
        allForms.filter { $0.institution == institution }
    }
    
    func descriptor(institution: Institution, kind: FormKind) -> FormDescriptor? {
        allForms.first { $0.institution == institution && $0.kind == kind }
    }
}
