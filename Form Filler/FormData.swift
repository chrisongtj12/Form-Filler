//
//  FormData.swift
//  Speedoc Clinical Notes
//
//  Form data structures
//

import Foundation

// MARK: - Medical Notes Data

struct MedicalNotesData: Codable {
    var patientName: String
    var patientNRIC: String
    var date: String
    var bp: String
    var spo2: String
    var pr: String
    var hypocount: String
    var pastHistory: String
    var hpi: String
    var physicalExam: String
    var issues: String
    var management: String
    var clinicianName: String
    var clinicianMCR: String
    
    init(
        patientName: String = "",
        patientNRIC: String = "",
        date: String = "",
        bp: String = "",
        spo2: String = "",
        pr: String = "",
        hypocount: String = "",
        pastHistory: String = "",
        hpi: String = "",
        physicalExam: String = "",
        issues: String = "",
        management: String = "",
        clinicianName: String = "",
        clinicianMCR: String = ""
    ) {
        self.patientName = patientName
        self.patientNRIC = patientNRIC
        self.date = date
        self.bp = bp
        self.spo2 = spo2
        self.pr = pr
        self.hypocount = hypocount
        self.pastHistory = pastHistory
        self.hpi = hpi
        self.physicalExam = physicalExam
        self.issues = issues
        self.management = management
        self.clinicianName = clinicianName
        self.clinicianMCR = clinicianMCR
    }
    
    /// Returns value for a given key path
    func value(for key: String) -> String {
        switch key {
        case "patient.name": return patientName
        case "patient.nric": return patientNRIC
        case "notes.date": return date
        case "notes.bp": return bp
        case "notes.spo2": return spo2
        case "notes.pr": return pr
        case "notes.hypocount": return hypocount
        case "notes.pastHistory": return pastHistory
        case "notes.hpi": return hpi
        case "notes.physicalExam": return physicalExam
        case "notes.issues": return issues
        case "notes.management": return management
        case "clinician.name": return clinicianName
        case "clinician.mcr": return clinicianMCR
        default: return ""
        }
    }
}

// MARK: - Home Visit Record Data

struct HVRecordRow: Codable, Identifiable {
    var id = UUID()
    var clientName: String
    var clientNRIC: String
    var dateTimeOfVisit: String
    var clientNOK: String
    var signatureText: String
    
    init(
        clientName: String = "",
        clientNRIC: String = "",
        dateTimeOfVisit: String = "",
        clientNOK: String = "",
        signatureText: String = ""
    ) {
        self.clientName = clientName
        self.clientNRIC = clientNRIC
        self.dateTimeOfVisit = dateTimeOfVisit
        self.clientNOK = clientNOK
        self.signatureText = signatureText
    }
    
    func value(for key: String) -> String {
        switch key {
        case "row.clientName": return clientName
        case "row.clientNRIC": return clientNRIC
        case "row.dateTimeOfVisit": return dateTimeOfVisit
        case "row.clientNOK": return clientNOK
        case "row.signatureText": return signatureText
        default: return ""
        }
    }
}

struct HVRecordData: Codable {
    var serviceType: String
    var clinicianName: String
    var rows: [HVRecordRow]
    
    init(serviceType: String = "Home Medical", clinicianName: String = "", rows: [HVRecordRow] = []) {
        self.serviceType = serviceType
        self.clinicianName = clinicianName
        self.rows = rows
    }
    
    func value(for key: String) -> String {
        switch key {
        case "hv.serviceType": return serviceType
        case "hv.clinicianName": return clinicianName
        default: return ""
        }
    }
}
