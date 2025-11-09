//
//  ClinicalNote.swift
//  Speedoc Clinical Notes
//
//  Data model for parsed AVIXO clinical notes
//

import Foundation

struct ClinicalNote: Equatable {
    var patientName: String = ""
    var nric: String = ""
    var dateOfVisit: String = ""   // keep as raw string; no date parsing for now
    var clientOrNOK: String = ""
    var bp: String = ""
    var spo2: String = ""
    var pr: String = ""
    var hypocount: String = ""
    var pmh: String = ""
    var presentingComplaint: String = ""
    var physicalExam: String = ""
    var issues: String = ""
    var plan: String = ""
    
    /// Returns a summary of which fields were filled
    var filledFieldsSummary: String {
        var filled: [String] = []
        var empty: [String] = []
        
        let fields: [(String, String)] = [
            ("Name", patientName),
            ("NRIC", nric),
            ("Date", dateOfVisit),
            ("Client/NOK", clientOrNOK),
            ("BP", bp),
            ("SpO2", spo2),
            ("PR", pr),
            ("Hypocount", hypocount),
            ("PMH", pmh),
            ("Presenting Complaint", presentingComplaint),
            ("Physical Exam", physicalExam),
            ("Issues", issues),
            ("Plan", plan)
        ]
        
        for (label, value) in fields {
            if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                empty.append(label)
            } else {
                filled.append(label)
            }
        }
        
        var summary = ""
        if !filled.isEmpty {
            summary += "✓ Filled: \(filled.joined(separator: ", "))"
        }
        if !empty.isEmpty {
            if !summary.isEmpty { summary += "\n" }
            summary += "○ Empty: \(empty.joined(separator: ", "))"
        }
        
        return summary.isEmpty ? "No fields parsed" : summary
    }
    
    /// Maps to MedicalNotesData
    func toMedicalNotesData(existingData: MedicalNotesData) -> MedicalNotesData {
        var updated = existingData
        
        if !patientName.isEmpty {
            updated.patientName = patientName
        }
        if !nric.isEmpty {
            updated.patientNRIC = nric
        }
        if !dateOfVisit.isEmpty {
            updated.date = dateOfVisit
        }
        if !bp.isEmpty {
            updated.bp = bp
        }
        if !spo2.isEmpty {
            updated.spo2 = spo2
        }
        if !pr.isEmpty {
            updated.pr = pr
        }
        if !hypocount.isEmpty {
            updated.hypocount = hypocount
        }
        if !pmh.isEmpty {
            updated.pastHistory = pmh
        }
        if !presentingComplaint.isEmpty {
            updated.hpi = presentingComplaint
        }
        if !physicalExam.isEmpty {
            updated.physicalExam = physicalExam
        }
        if !issues.isEmpty {
            updated.issues = issues
        }
        if !plan.isEmpty {
            updated.management = plan
        }
        
        return updated
    }
}
