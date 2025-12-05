//
//  Institution.swift
//  Speedoc Clinical Notes
//
//  Multi-institution support - data models
//

import Foundation
// Removed UIKit to keep multiplatform compatibility

// MARK: - Institution

struct Institution: Identifiable, Codable, Equatable {
    let id: UUID
    var displayName: String
    var subtitle: String
    var iconName: String
    var institutionType: InstitutionType?
    
    init(
        id: UUID = UUID(),
        displayName: String,
        subtitle: String,
        iconName: String = "building.2.fill",
        institutionType: InstitutionType? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.subtitle = subtitle
        self.iconName = iconName
        self.institutionType = institutionType
    }
    
    // MARK: - Predefined Institutions
    
    static let activeGlobal = Institution(
        displayName: "Active Global",
        subtitle: "Medical Notes, HV Record",
        iconName: "building.2.fill",
        institutionType: .activeGlobal
    )
    
    static let lentor = Institution(
        displayName: "Lentor",
        subtitle: "Medical Notes, HV Record",
        iconName: "building.fill",
        institutionType: .lentor
    )
    
    // MARK: - Default List
    
    static var defaultInstitutions: [Institution] {
        [.activeGlobal, .lentor]
    }
}

// MARK: - Institution Type

enum InstitutionType: String, Codable {
    case activeGlobal = "Active Global"
    case lentor = "Lentor"
}

// rest unchanged…
