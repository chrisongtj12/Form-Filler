//
//  Clinician.swift
//  Speedoc Clinical Notes
//
//  Clinician data model
//

import Foundation

struct Clinician: Codable {
    var displayName: String
    var mcrNumber: String
    var defaultSignatureImagePNGBase64: String?
}
