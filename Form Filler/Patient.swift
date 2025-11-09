//
//  Patient.swift
//  Speedoc Clinical Notes
//
//  Patient data model
//

import Foundation
import Combine

struct Patient: Codable, Identifiable {
    var id = UUID()
    var name: String
    var nric: String
    var dateOfBirth: String?
}
