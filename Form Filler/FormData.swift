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

// MARK: - Lentor Medical Notes Data

struct LentorMedicalNotesData: Codable {
    // Top section
    var patientName: String
    var nric: String
    var dateOfVisit: String
    var nokName: String
    var nokContact: String
    
    // Vitals
    var temp: String
    var rr: String
    var bp: String
    var spo2: String
    var pr: String
    var hc: String
    
    // Weight trend
    var weightMostRecent: String
    var weightLeastRecent: String
    
    // General Condition
    var gcIssue1: String // Mood/Behaviour/Sleep
    var gcIssue2: String // Oral Intake/Appetite
    var gcIssue3: String // Pain
    var gcIssue4: String // BO
    var gcIssue5: String // Skin
    var gcIssue6: String // Falls
    var gcIssue7: String // Other issues
    var physicalExam: String
    
    // Page 2
    var tcuPlan6m: String
    
    // Document review checkboxes
    var docLabReportsChecked: Bool
    var docLabTrendChartFill: Bool
    var docLabTrendChartPresent: Bool
    var docMedRecRecon: Bool
    var docOthersText: String
    
    // Plan table
    var planMedChanges: String
    var planLabTests: String
    var planSpecialMonitoring: String
    
    // Page 3
    var planFollowUpReview: String
    var planReferralsMemos: String
    var planACP: String
    var planOthersUpdateNOK: String
    
    // Doctor details
    var doctorName: String
    var doctorMCR: String
    var doctorESign: String
    
    init(
        patientName: String = "",
        nric: String = "",
        dateOfVisit: String = "",
        nokName: String = "",
        nokContact: String = "",
        temp: String = "",
        rr: String = "",
        bp: String = "",
        spo2: String = "",
        pr: String = "",
        hc: String = "",
        weightMostRecent: String = "",
        weightLeastRecent: String = "",
        gcIssue1: String = "",
        gcIssue2: String = "",
        gcIssue3: String = "",
        gcIssue4: String = "",
        gcIssue5: String = "",
        gcIssue6: String = "",
        gcIssue7: String = "",
        physicalExam: String = "",
        tcuPlan6m: String = "",
        docLabReportsChecked: Bool = false,
        docLabTrendChartFill: Bool = false,
        docLabTrendChartPresent: Bool = false,
        docMedRecRecon: Bool = false,
        docOthersText: String = "",
        planMedChanges: String = "",
        planLabTests: String = "",
        planSpecialMonitoring: String = "",
        planFollowUpReview: String = "",
        planReferralsMemos: String = "",
        planACP: String = "",
        planOthersUpdateNOK: String = "",
        doctorName: String = "",
        doctorMCR: String = "",
        doctorESign: String = ""
    ) {
        self.patientName = patientName
        self.nric = nric
        self.dateOfVisit = dateOfVisit
        self.nokName = nokName
        self.nokContact = nokContact
        self.temp = temp
        self.rr = rr
        self.bp = bp
        self.spo2 = spo2
        self.pr = pr
        self.hc = hc
        self.weightMostRecent = weightMostRecent
        self.weightLeastRecent = weightLeastRecent
        self.gcIssue1 = gcIssue1
        self.gcIssue2 = gcIssue2
        self.gcIssue3 = gcIssue3
        self.gcIssue4 = gcIssue4
        self.gcIssue5 = gcIssue5
        self.gcIssue6 = gcIssue6
        self.gcIssue7 = gcIssue7
        self.physicalExam = physicalExam
        self.tcuPlan6m = tcuPlan6m
        self.docLabReportsChecked = docLabReportsChecked
        self.docLabTrendChartFill = docLabTrendChartFill
        self.docLabTrendChartPresent = docLabTrendChartPresent
        self.docMedRecRecon = docMedRecRecon
        self.docOthersText = docOthersText
        self.planMedChanges = planMedChanges
        self.planLabTests = planLabTests
        self.planSpecialMonitoring = planSpecialMonitoring
        self.planFollowUpReview = planFollowUpReview
        self.planReferralsMemos = planReferralsMemos
        self.planACP = planACP
        self.planOthersUpdateNOK = planOthersUpdateNOK
        self.doctorName = doctorName
        self.doctorMCR = doctorMCR
        self.doctorESign = doctorESign
    }
    
    func value(for key: String) -> String {
        switch key {
        case "lentor.patientName": return patientName
        case "lentor.nric": return nric
        case "lentor.dateOfVisit": return dateOfVisit
        case "lentor.nokName": return nokName
        case "lentor.nokContact": return nokContact
        case "lentor.temp": return temp
        case "lentor.rr": return rr
        case "lentor.bp": return bp
        case "lentor.spo2": return spo2
        case "lentor.pr": return pr
        case "lentor.hc": return hc
        case "lentor.weightMostRecent": return weightMostRecent
        case "lentor.weightLeastRecent": return weightLeastRecent
        case "lentor.gcIssue1": return gcIssue1
        case "lentor.gcIssue2": return gcIssue2
        case "lentor.gcIssue3": return gcIssue3
        case "lentor.gcIssue4": return gcIssue4
        case "lentor.gcIssue5": return gcIssue5
        case "lentor.gcIssue6": return gcIssue6
        case "lentor.gcIssue7": return gcIssue7
        case "lentor.physicalExam": return physicalExam
        case "lentor.tcuPlan6m": return tcuPlan6m
        case "lentor.docLabReportsChecked": return docLabReportsChecked ? "✓" : ""
        case "lentor.docLabTrendChartFill": return docLabTrendChartFill ? "✓" : ""
        case "lentor.docLabTrendChartPresent": return docLabTrendChartPresent ? "✓" : ""
        case "lentor.docMedRecRecon": return docMedRecRecon ? "✓" : ""
        case "lentor.docOthersText": return docOthersText
        case "lentor.planMedChanges": return planMedChanges
        case "lentor.planLabTests": return planLabTests
        case "lentor.planSpecialMonitoring": return planSpecialMonitoring
        case "lentor.planFollowUpReview": return planFollowUpReview
        case "lentor.planReferralsMemos": return planReferralsMemos
        case "lentor.planACP": return planACP
        case "lentor.planOthersUpdateNOK": return planOthersUpdateNOK
        case "lentor.doctorName": return doctorName
        case "lentor.doctorMCR": return doctorMCR
        case "lentor.doctorESign": return doctorESign
        default: return ""
        }
    }
}

// MARK: - Lentor Home Visit Record Data

struct LentorAttendanceRow: Codable, Identifiable {
    var id = UUID()
    var date: String
    var timeStart: String
    var timeEnd: String
    var totalHours: String
    var typeOfServices: String // HN/HM/HPC/HT
    var caregiverSignature: String
    var hcStaffSignature: String
    
    init(
        date: String = "",
        timeStart: String = "",
        timeEnd: String = "",
        totalHours: String = "",
        typeOfServices: String = "",
        caregiverSignature: String = "",
        hcStaffSignature: String = ""
    ) {
        self.date = date
        self.timeStart = timeStart
        self.timeEnd = timeEnd
        self.totalHours = totalHours
        self.typeOfServices = typeOfServices
        self.caregiverSignature = caregiverSignature
        self.hcStaffSignature = hcStaffSignature
    }
    
    func value(for key: String) -> String {
        switch key {
        case "lentorRow.date": return date
        case "lentorRow.timeStart": return timeStart
        case "lentorRow.timeEnd": return timeEnd
        case "lentorRow.totalHours": return totalHours
        case "lentorRow.typeOfServices": return typeOfServices
        case "lentorRow.caregiverSignature": return caregiverSignature
        case "lentorRow.hcStaffSignature": return hcStaffSignature
        default: return ""
        }
    }
}

struct LentorHVRecordData: Codable {
    var clientName: String
    var clientNRIC: String
    var serviceLocation: String
    var serviceContact: String
    var caregiverName: String
    var caregiverNRIC: String
    var caregiverAddress: String
    var caregiverContact: String
    var rows: [LentorAttendanceRow]
    
    init(
        clientName: String = "",
        clientNRIC: String = "",
        serviceLocation: String = "",
        serviceContact: String = "",
        caregiverName: String = "",
        caregiverNRIC: String = "",
        caregiverAddress: String = "",
        caregiverContact: String = "",
        rows: [LentorAttendanceRow] = []
    ) {
        self.clientName = clientName
        self.clientNRIC = clientNRIC
        self.serviceLocation = serviceLocation
        self.serviceContact = serviceContact
        self.caregiverName = caregiverName
        self.caregiverNRIC = caregiverNRIC
        self.caregiverAddress = caregiverAddress
        self.caregiverContact = caregiverContact
        self.rows = rows
    }
    
    func value(for key: String) -> String {
        switch key {
        case "lentorHV.clientName": return clientName
        case "lentorHV.clientNRIC": return clientNRIC
        case "lentorHV.serviceLocation": return serviceLocation
        case "lentorHV.serviceContact": return serviceContact
        case "lentorHV.caregiverName": return caregiverName
        case "lentorHV.caregiverNRIC": return caregiverNRIC
        case "lentorHV.caregiverAddress": return caregiverAddress
        case "lentorHV.caregiverContact": return caregiverContact
        default: return ""
        }
    }
}
