//
//  Institution.swift
//  Speedoc Clinical Notes
//
//  Multi-institution support - data models
//

import Foundation
// Removed UIKit to keep multiplatform compatibility

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

// rest unchanged…
