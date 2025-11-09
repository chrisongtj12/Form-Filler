//
//  Patient.swift
//  Speedoc Clinical Notes
//
//  Patient data model
//

import Foundation

struct Patient: Codable, Identifiable {
    var id = UUID()
    var name: String
    var nric: String
    var dateOfBirth: String?
}
