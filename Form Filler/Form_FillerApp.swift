//
//  Form_FillerApp.swift
//  Speedoc Clinical Notes
//
//  Main app entry point
//

import SwiftUI
import Combine

@main
struct Form_FillerApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(appState)
                .onAppear {
                    appState.initializeDefaultsIfNeeded()
                }
        }
    }
}

/// Central state manager for the app
class AppState: ObservableObject {
    @Published var clinician: Clinician
    @Published var lastUsedPatient: Patient?
    @Published var templates: [Template] = []
    @Published var institutions: [Institution] = []
    
    // BV Notes view model
    let bvNotesViewModel = BVNotesViewModel()
    
    // Active Global draft states
    @Published var medicalNotesDraft: MedicalNotesData
    @Published var hvRecordDraft: HVRecordData
    
    // Lentor draft states
    @Published var lentorMedicalNotesDraft: LentorMedicalNotesData
    @Published var lentorHVRecordDraft: LentorHVRecordData
    
    private let clinicianKey = "clinician"
    private let lastPatientKey = "lastPatient"
    private let institutionsKey = "institutions"
    private let medicalNotesDraftKey = "medicalNotesDraft"
    private let hvRecordDraftKey = "hvRecordDraft"
    private let lentorMedicalNotesDraftKey = "lentorMedicalNotesDraft"
    private let lentorHVRecordDraftKey = "lentorHVRecordDraft"
    
    init() {
        // Load clinician
        if let data = UserDefaults.standard.data(forKey: clinicianKey),
           let clinician = try? JSONDecoder().decode(Clinician.self, from: data) {
            self.clinician = clinician
        } else {
            self.clinician = Clinician(displayName: "", mcrNumber: "", defaultSignatureImagePNGBase64: nil)
        }
        
        // Load institutions
        if let data = UserDefaults.standard.data(forKey: institutionsKey),
           let institutions = try? JSONDecoder().decode([Institution].self, from: data) {
            self.institutions = institutions
        } else {
            self.institutions = Institution.defaultInstitutions
        }
        
        // Load last patient
        if let data = UserDefaults.standard.data(forKey: lastPatientKey),
           let patient = try? JSONDecoder().decode(Patient.self, from: data) {
            self.lastUsedPatient = patient
        }
        
        // Load Active Global medical notes draft
        if let data = UserDefaults.standard.data(forKey: medicalNotesDraftKey),
           let draft = try? JSONDecoder().decode(MedicalNotesData.self, from: data) {
            self.medicalNotesDraft = draft
        } else {
            self.medicalNotesDraft = MedicalNotesData()
        }
        
        // Load Active Global HV record draft
        if let data = UserDefaults.standard.data(forKey: hvRecordDraftKey),
           let draft = try? JSONDecoder().decode(HVRecordData.self, from: data) {
            self.hvRecordDraft = draft
        } else {
            self.hvRecordDraft = HVRecordData(serviceType: "Home Medical", clinicianName: "", rows: [])
        }
        
        // Load Lentor medical notes draft
        if let data = UserDefaults.standard.data(forKey: lentorMedicalNotesDraftKey),
           let draft = try? JSONDecoder().decode(LentorMedicalNotesData.self, from: data) {
            self.lentorMedicalNotesDraft = draft
        } else {
            self.lentorMedicalNotesDraft = LentorMedicalNotesData()
        }
        
        // Load Lentor HV record draft
        if let data = UserDefaults.standard.data(forKey: lentorHVRecordDraftKey),
           let draft = try? JSONDecoder().decode(LentorHVRecordData.self, from: data) {
            self.lentorHVRecordDraft = draft
        } else {
            self.lentorHVRecordDraft = LentorHVRecordData()
        }
    }
    
    func initializeDefaultsIfNeeded() {
        // Load or create default templates
        if templates.isEmpty {
            templates = TemplateManager.shared.loadTemplates()
        }
    }
    
    func saveClinician() {
        if let data = try? JSONEncoder().encode(clinician) {
            UserDefaults.standard.set(data, forKey: clinicianKey)
        }
    }
    
    func saveInstitutions() {
        if let data = try? JSONEncoder().encode(institutions) {
            UserDefaults.standard.set(data, forKey: institutionsKey)
        }
    }
    
    func saveLastPatient(_ patient: Patient) {
        lastUsedPatient = patient
        if let data = try? JSONEncoder().encode(patient) {
            UserDefaults.standard.set(data, forKey: lastPatientKey)
        }
    }
    
    func saveMedicalNotesDraft() {
        if let data = try? JSONEncoder().encode(medicalNotesDraft) {
            UserDefaults.standard.set(data, forKey: medicalNotesDraftKey)
        }
    }
    
    func saveHVRecordDraft() {
        if let data = try? JSONEncoder().encode(hvRecordDraft) {
            UserDefaults.standard.set(data, forKey: hvRecordDraftKey)
        }
    }
    
    func saveLentorMedicalNotesDraft() {
        if let data = try? JSONEncoder().encode(lentorMedicalNotesDraft) {
            UserDefaults.standard.set(data, forKey: lentorMedicalNotesDraftKey)
        }
    }
    
    func saveLentorHVRecordDraft() {
        if let data = try? JSONEncoder().encode(lentorHVRecordDraft) {
            UserDefaults.standard.set(data, forKey: lentorHVRecordDraftKey)
        }
    }
    
    func saveTemplates(_ updated: [Template]? = nil) {
        if let updated {
            templates = updated
        }
        TemplateManager.shared.saveTemplates(templates)
    }
    
    func restoreDefaultTemplates() {
        templates = TemplateManager.shared.restoreDefaults()
    }
}

/// Manages template persistence
class TemplateManager {
    static let shared = TemplateManager()
    
    private let templatesFileName = "templates.json"
    
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var templatesFileURL: URL {
        documentsDirectory.appendingPathComponent(templatesFileName)
    }
    
    func loadTemplates() -> [Template] {
        // Try to load from documents directory
        if let data = try? Data(contentsOf: templatesFileURL),
           let templates = try? JSONDecoder().decode([Template].self, from: data) {
            return templates
        }
        
        // Otherwise, load defaults and save them
        let defaults = createDefaultTemplates()
        saveTemplates(defaults)
        return defaults
    }
    
    func saveTemplates(_ templates: [Template]) {
        if let data = try? JSONEncoder().encode(templates) {
            try? data.write(to: templatesFileURL)
        }
    }
    
    func restoreDefaults() -> [Template] {
        let defaults = createDefaultTemplates()
        saveTemplates(defaults)
        return defaults
    }
    
    private func createDefaultTemplates() -> [Template] {
        var templates: [Template] = [
            createMedicalNotesPage1Template(),
            createMedicalNotesPage2Template(),
            createHomeVisitRecordTemplate()
        ]
        
        // Add Lentor defaults
        templates.append(contentsOf: [
            createLentorMedicalNotesPage1Template(),
            createLentorMedicalNotesPage2Template(),
            createLentorMedicalNotesPage3Template(),
            createLentorHVRecordTemplate()
        ])
        
        return templates
    }
    
    // MARK: - Active Global templates
    
    private func createMedicalNotesPage1Template() -> Template {
        Template(
            name: "Active Global Medical Notes (Page 1)",
            backgroundImageName: "AG_MedicalNotes_p1",
            pageIndex: 1,
            fields: [
                TemplateField(
                    key: "patient.name",
                    label: "NAME OF CLIENT",
                    kind: .text,
                    frame: CGRectCodable(x: 150, y: 120, width: 400, height: 30),
                    fontSize: 14,
                    alignment: .left,
                    placeholder: "Patient Name"
                ),
                TemplateField(
                    key: "patient.nric",
                    label: "NRIC OF CLIENT",
                    kind: .text,
                    frame: CGRectCodable(x: 150, y: 160, width: 300, height: 30),
                    fontSize: 14,
                    alignment: .left,
                    placeholder: "NRIC"
                ),
                TemplateField(
                    key: "notes.date",
                    label: "DATE",
                    kind: .datetime,
                    frame: CGRectCodable(x: 500, y: 160, width: 200, height: 30),
                    fontSize: 14,
                    alignment: .left,
                    placeholder: "Date"
                ),
                TemplateField(
                    key: "notes.bp",
                    label: "BP",
                    kind: .text,
                    frame: CGRectCodable(x: 150, y: 220, width: 120, height: 30),
                    fontSize: 12,
                    alignment: .left,
                    placeholder: "BP"
                ),
                TemplateField(
                    key: "notes.spo2",
                    label: "SpO2",
                    kind: .text,
                    frame: CGRectCodable(x: 300, y: 220, width: 100, height: 30),
                    fontSize: 12,
                    alignment: .left,
                    placeholder: "SpO2"
                ),
                TemplateField(
                    key: "notes.pr",
                    label: "PR",
                    kind: .text,
                    frame: CGRectCodable(x: 430, y: 220, width: 100, height: 30),
                    fontSize: 12,
                    alignment: .left,
                    placeholder: "PR"
                ),
                TemplateField(
                    key: "notes.hypocount",
                    label: "Hypo Count",
                    kind: .text,
                    frame: CGRectCodable(x: 560, y: 220, width: 120, height: 30),
                    fontSize: 12,
                    alignment: .left,
                    placeholder: "Hypo Count"
                ),
                TemplateField(
                    key: "notes.pastHistory",
                    label: "Past Medical History",
                    kind: .multiline,
                    frame: CGRectCodable(x: 80, y: 280, width: 650, height: 120),
                    fontSize: 12,
                    alignment: .left,
                    placeholder: "Past Medical History"
                ),
                TemplateField(
                    key: "notes.hpi",
                    label: "History of Presenting Complaint",
                    kind: .multiline,
                    frame: CGRectCodable(x: 80, y: 430, width: 650, height: 150),
                    fontSize: 12,
                    alignment: .left,
                    placeholder: "History of Presenting Complaint"
                ),
                TemplateField(
                    key: "notes.physicalExam",
                    label: "Physical Examination",
                    kind: .multiline,
                    frame: CGRectCodable(x: 80, y: 610, width: 650, height: 150),
                    fontSize: 12,
                    alignment: .left,
                    placeholder: "Physical Examination"
                )
            ]
        )
    }
    
    private func createMedicalNotesPage2Template() -> Template {
        Template(
            name: "Active Global Medical Notes (Page 2)",
            backgroundImageName: "AG_MedicalNotes_p2",
            pageIndex: 2,
            fields: [
                TemplateField(
                    key: "notes.issues",
                    label: "Issues / Diagnosis",
                    kind: .multiline,
                    frame: CGRectCodable(x: 80, y: 100, width: 650, height: 200),
                    fontSize: 12,
                    alignment: .left,
                    placeholder: "Issues / Diagnosis"
                ),
                TemplateField(
                    key: "notes.management",
                    label: "Management / Plan",
                    kind: .multiline,
                    frame: CGRectCodable(x: 80, y: 330, width: 650, height: 250),
                    fontSize: 12,
                    alignment: .left,
                    placeholder: "Management / Plan"
                ),
                TemplateField(
                    key: "clinician.name",
                    label: "Clinician Name",
                    kind: .text,
                    frame: CGRectCodable(x: 100, y: 620, width: 300, height: 30),
                    fontSize: 14,
                    alignment: .left,
                    placeholder: "Clinician Name"
                ),
                TemplateField(
                    key: "clinician.mcr",
                    label: "MCR Number",
                    kind: .text,
                    frame: CGRectCodable(x: 430, y: 620, width: 250, height: 30),
                    fontSize: 14,
                    alignment: .left,
                    placeholder: "MCR Number"
                )
            ]
        )
    }
    
    private func createHomeVisitRecordTemplate() -> Template {
        Template(
            name: "Active Global Home Visit Record",
            backgroundImageName: "AG_HomeVisitRecord",
            pageIndex: 1,
            fields: [
                TemplateField(
                    key: "hv.serviceType",
                    label: "Service Type",
                    kind: .picker,
                    frame: CGRectCodable(x: 150, y: 100, width: 300, height: 30),
                    fontSize: 14,
                    alignment: .left,
                    placeholder: "Service Type"
                ),
                TemplateField(
                    key: "hv.clinicianName",
                    label: "Clinician Name",
                    kind: .text,
                    frame: CGRectCodable(x: 470, y: 100, width: 270, height: 30),
                    fontSize: 14,
                    alignment: .left,
                    placeholder: "Clinician Name"
                ),
                TemplateField(
                    key: "row.clientName",
                    label: "Client Name",
                    kind: .text,
                    frame: CGRectCodable(x: 80, y: 180, width: 150, height: 40),
                    fontSize: 11,
                    alignment: .left,
                    placeholder: ""
                ),
                TemplateField(
                    key: "row.clientNRIC",
                    label: "NRIC",
                    kind: .text,
                    frame: CGRectCodable(x: 235, y: 180, width: 130, height: 40),
                    fontSize: 11,
                    alignment: .left,
                    placeholder: ""
                ),
                TemplateField(
                    key: "row.dateTimeOfVisit",
                    label: "Date/Time",
                    kind: .text,
                    frame: CGRectCodable(x: 370, y: 180, width: 140, height: 40),
                    fontSize: 11,
                    alignment: .left,
                    placeholder: ""
                ),
                TemplateField(
                    key: "row.clientNOK",
                    label: "NOK",
                    kind: .text,
                    frame: CGRectCodable(x: 515, y: 180, width: 120, height: 40),
                    fontSize: 11,
                    alignment: .left,
                    placeholder: ""
                ),
                TemplateField(
                    key: "row.signatureText",
                    label: "Signature",
                    kind: .text,
                    frame: CGRectCodable(x: 640, y: 180, width: 100, height: 40),
                    fontSize: 11,
                    alignment: .left,
                    placeholder: ""
                )
            ]
        )
    }
    
    // MARK: - Lentor defaults
    
    private func createLentorMedicalNotesPage1Template() -> Template {
        Template(
            name: "Lentor Medical Notes (Page 1)",
            backgroundImageName: "Lentor_MedicalNotes_p1",
            pageIndex: 1,
            fields: [
                // Top
                TemplateField(key: "lentor.patientName", label: "Name of Client", kind: .text, frame: CGRectCodable(x: 120, y: 110, width: 420, height: 28), fontSize: 13, alignment: .left, placeholder: "Name"),
                TemplateField(key: "lentor.nric", label: "NRIC of Client", kind: .text, frame: CGRectCodable(x: 120, y: 145, width: 220, height: 28), fontSize: 13, alignment: .left, placeholder: "NRIC"),
                TemplateField(key: "lentor.dateOfVisit", label: "Date of Visit", kind: .datetime, frame: CGRectCodable(x: 380, y: 145, width: 160, height: 28), fontSize: 13, alignment: .left, placeholder: "dd/MM/yyyy"),
                TemplateField(key: "lentor.nokName", label: "NOK Name", kind: .text, frame: CGRectCodable(x: 120, y: 180, width: 220, height: 28), fontSize: 13, alignment: .left, placeholder: "NOK"),
                TemplateField(key: "lentor.nokContact", label: "NOK Contact No", kind: .text, frame: CGRectCodable(x: 380, y: 180, width: 160, height: 28), fontSize: 13, alignment: .left, placeholder: "Phone"),
                
                // Vitals
                TemplateField(key: "lentor.temp", label: "Temp", kind: .text, frame: CGRectCodable(x: 120, y: 225, width: 80, height: 24), fontSize: 12, alignment: .left, placeholder: ""),
                TemplateField(key: "lentor.rr", label: "RR", kind: .text, frame: CGRectCodable(x: 210, y: 225, width: 60, height: 24), fontSize: 12, alignment: .left, placeholder: ""),
                TemplateField(key: "lentor.bp", label: "BP", kind: .text, frame: CGRectCodable(x: 280, y: 225, width: 90, height: 24), fontSize: 12, alignment: .left, placeholder: ""),
                TemplateField(key: "lentor.spo2", label: "SpO2", kind: .text, frame: CGRectCodable(x: 380, y: 225, width: 70, height: 24), fontSize: 12, alignment: .left, placeholder: ""),
                TemplateField(key: "lentor.pr", label: "PR", kind: .text, frame: CGRectCodable(x: 460, y: 225, width: 70, height: 24), fontSize: 12, alignment: .left, placeholder: ""),
                TemplateField(key: "lentor.hc", label: "H/C", kind: .text, frame: CGRectCodable(x: 540, y: 225, width: 80, height: 24), fontSize: 12, alignment: .left, placeholder: ""),
                
                // Weight trend
                TemplateField(key: "lentor.weightMostRecent", label: "Weight Most Recent", kind: .text, frame: CGRectCodable(x: 120, y: 260, width: 160, height: 24), fontSize: 12, alignment: .left, placeholder: ""),
                TemplateField(key: "lentor.weightLeastRecent", label: "Weight Least Recent", kind: .text, frame: CGRectCodable(x: 300, y: 260, width: 160, height: 24), fontSize: 12, alignment: .left, placeholder: ""),
                
                // General Condition (free text cells)
                TemplateField(key: "lentor.gcIssue1", label: "Mood/Behaviour/Sleep", kind: .multiline, frame: CGRectCodable(x: 80, y: 300, width: 640, height: 60), fontSize: 11, alignment: .left, placeholder: ""),
                TemplateField(key: "lentor.gcIssue2", label: "Oral Intake/Appetite/NG Aspirates", kind: .multiline, frame: CGRectCodable(x: 80, y: 365, width: 640, height: 60), fontSize: 11, alignment: .left, placeholder: ""),
                TemplateField(key: "lentor.gcIssue3", label: "Pain (if any)", kind: .multiline, frame: CGRectCodable(x: 80, y: 430, width: 640, height: 50), fontSize: 11, alignment: .left, placeholder: ""),
                TemplateField(key: "lentor.gcIssue4", label: "BO", kind: .multiline, frame: CGRectCodable(x: 80, y: 485, width: 640, height: 50), fontSize: 11, alignment: .left, placeholder: ""),
                TemplateField(key: "lentor.gcIssue5", label: "Skin", kind: .multiline, frame: CGRectCodable(x: 80, y: 540, width: 640, height: 50), fontSize: 11, alignment: .left, placeholder: ""),
                TemplateField(key: "lentor.gcIssue6", label: "Falls (last 6/12)", kind: .multiline, frame: CGRectCodable(x: 80, y: 595, width: 640, height: 50), fontSize: 11, alignment: .left, placeholder: ""),
                TemplateField(key: "lentor.gcIssue7", label: "Other issues", kind: .multiline, frame: CGRectCodable(x: 80, y: 650, width: 640, height: 70), fontSize: 11, alignment: .left, placeholder: "")
                
                // Note: Physical Examination moved to Page 2
            ]
        )
    }
    
    private func createLentorMedicalNotesPage2Template() -> Template {
        Template(
            name: "Lentor Medical Notes (Page 2)",
            backgroundImageName: "Lentor_MedicalNotes_p2",
            pageIndex: 2,
            fields: [
                // TCUs plan
                TemplateField(key: "lentor.tcuPlan6m", label: "TCUs next 6 months", kind: .multiline, frame: CGRectCodable(x: 80, y: 100, width: 640, height: 100), fontSize: 11, alignment: .left, placeholder: ""),
                
                // Move Physical Examination here (kept same width; adjust y as needed in editor)
                TemplateField(key: "lentor.physicalExam", label: "Physical Examination", kind: .multiline, frame: CGRectCodable(x: 80, y: 210, width: 640, height: 100), fontSize: 11, alignment: .left, placeholder: ""),
                
                // Document review (checkbox-like, we render ✓)
                TemplateField(key: "lentor.docLabReportsChecked", label: "Lab reports checked", kind: .text, frame: CGRectCodable(x: 80, y: 330, width: 200, height: 24), fontSize: 12, alignment: .left, placeholder: ""),
                TemplateField(key: "lentor.docLabTrendChartFill", label: "Lab trend chart filled", kind: .text, frame: CGRectCodable(x: 80, y: 360, width: 200, height: 24), fontSize: 12, alignment: .left, placeholder: ""),
                TemplateField(key: "lentor.docLabTrendChartPresent", label: "Lab trend chart present", kind: .text, frame: CGRectCodable(x: 80, y: 390, width: 220, height: 24), fontSize: 12, alignment: .left, placeholder: ""),
                TemplateField(key: "lentor.docMedRecRecon", label: "Med rec reconciliation", kind: .text, frame: CGRectCodable(x: 80, y: 420, width: 220, height: 24), fontSize: 12, alignment: .left, placeholder: ""),
                TemplateField(key: "lentor.docOthersText", label: "Others", kind: .text, frame: CGRectCodable(x: 80, y: 450, width: 640, height: 24), fontSize: 12, alignment: .left, placeholder: ""),
                
                // Plan table
                TemplateField(key: "lentor.planMedChanges", label: "Medication Changes", kind: .multiline, frame: CGRectCodable(x: 80, y: 490, width: 640, height: 80), fontSize: 11, alignment: .left, placeholder: ""),
                TemplateField(key: "lentor.planLabTests", label: "Lab Tests", kind: .multiline, frame: CGRectCodable(x: 80, y: 580, width: 640, height: 80), fontSize: 11, alignment: .left, placeholder: ""),
                TemplateField(key: "lentor.planSpecialMonitoring", label: "Special Monitoring", kind: .multiline, frame: CGRectCodable(x: 80, y: 670, width: 640, height: 80), fontSize: 11, alignment: .left, placeholder: "")
            ]
        )
    }
    
    private func createLentorMedicalNotesPage3Template() -> Template {
        Template(
            name: "Lentor Medical Notes (Page 3)",
            backgroundImageName: "Lentor_MedicalNotes_p3",
            pageIndex: 3,
            fields: [
                TemplateField(key: "lentor.planFollowUpReview", label: "Follow-up Review", kind: .multiline, frame: CGRectCodable(x: 80, y: 100, width: 640, height: 90), fontSize: 11, alignment: .left, placeholder: ""),
                TemplateField(key: "lentor.planReferralsMemos", label: "Referrals / Memos", kind: .multiline, frame: CGRectCodable(x: 80, y: 195, width: 640, height: 90), fontSize: 11, alignment: .left, placeholder: ""),
                TemplateField(key: "lentor.planACP", label: "ACP", kind: .multiline, frame: CGRectCodable(x: 80, y: 290, width: 640, height: 90), fontSize: 11, alignment: .left, placeholder: ""),
                TemplateField(key: "lentor.planOthersUpdateNOK", label: "Others / Update NOK", kind: .multiline, frame: CGRectCodable(x: 80, y: 385, width: 640, height: 90), fontSize: 11, alignment: .left, placeholder: ""),
                
                // Doctor details
                TemplateField(key: "lentor.doctorName", label: "Doctor Name", kind: .text, frame: CGRectCodable(x: 120, y: 500, width: 300, height: 28), fontSize: 13, alignment: .left, placeholder: ""),
                TemplateField(key: "lentor.doctorMCR", label: "Doctor MCR", kind: .text, frame: CGRectCodable(x: 440, y: 500, width: 200, height: 28), fontSize: 13, alignment: .left, placeholder: ""),
                TemplateField(key: "lentor.doctorESign", label: "Doctor e-Signature", kind: .text, frame: CGRectCodable(x: 120, y: 540, width: 520, height: 60), fontSize: 13, alignment: .left, placeholder: "Signature")
            ]
        )
    }
    
    private func createLentorHVRecordTemplate() -> Template {
        Template(
            name: "Lentor Service Attendance Record",
            backgroundImageName: "Lentor_HomeVisitRecord",
            pageIndex: 1,
            fields: [
                // Header block
                TemplateField(key: "lentorHV.clientName", label: "Client Name", kind: .text, frame: CGRectCodable(x: 120, y: 110, width: 280, height: 24), fontSize: 12, alignment: .left, placeholder: ""),
                TemplateField(key: "lentorHV.clientNRIC", label: "Client NRIC", kind: .text, frame: CGRectCodable(x: 420, y: 110, width: 200, height: 24), fontSize: 12, alignment: .left, placeholder: ""),
                TemplateField(key: "lentorHV.serviceLocation", label: "Service Location", kind: .text, frame: CGRectCodable(x: 120, y: 140, width: 280, height: 24), fontSize: 12, alignment: .left, placeholder: ""),
                TemplateField(key: "lentorHV.serviceContact", label: "Service Contact", kind: .text, frame: CGRectCodable(x: 420, y: 140, width: 200, height: 24), fontSize: 12, alignment: .left, placeholder: ""),
                TemplateField(key: "lentorHV.caregiverName", label: "Caregiver Name", kind: .text, frame: CGRectCodable(x: 120, y: 170, width: 280, height: 24), fontSize: 12, alignment: .left, placeholder: ""),
                TemplateField(key: "lentorHV.caregiverNRIC", label: "Caregiver NRIC", kind: .text, frame: CGRectCodable(x: 420, y: 170, width: 200, height: 24), fontSize: 12, alignment: .left, placeholder: ""),
                TemplateField(key: "lentorHV.caregiverAddress", label: "Caregiver Address", kind: .text, frame: CGRectCodable(x: 120, y: 200, width: 500, height: 24), fontSize: 12, alignment: .left, placeholder: ""),
                TemplateField(key: "lentorHV.caregiverContact", label: "Caregiver Contact", kind: .text, frame: CGRectCodable(x: 120, y: 230, width: 280, height: 24), fontSize: 12, alignment: .left, placeholder: ""),
                
                // Attendance row prototype (first row positions; we’ll offset per row)
                TemplateField(key: "lentorRow.date", label: "Date", kind: .text, frame: CGRectCodable(x: 60, y: 290, width: 90, height: 36), fontSize: 11, alignment: .left, placeholder: ""),
                TemplateField(key: "lentorRow.timeStart", label: "Start", kind: .text, frame: CGRectCodable(x: 155, y: 290, width: 70, height: 36), fontSize: 11, alignment: .left, placeholder: ""),
                TemplateField(key: "lentorRow.timeEnd", label: "End", kind: .text, frame: CGRectCodable(x: 230, y: 290, width: 70, height: 36), fontSize: 11, alignment: .left, placeholder: ""),
                TemplateField(key: "lentorRow.totalHours", label: "Hours", kind: .text, frame: CGRectCodable(x: 305, y: 290, width: 60, height: 36), fontSize: 11, alignment: .left, placeholder: ""),
                TemplateField(key: "lentorRow.typeOfServices", label: "Type", kind: .text, frame: CGRectCodable(x: 370, y: 290, width: 80, height: 36), fontSize: 11, alignment: .left, placeholder: "HN/HM/HPC/HT"),
                TemplateField(key: "lentorRow.caregiverSignature", label: "Caregiver Sig", kind: .text, frame: CGRectCodable(x: 455, y: 290, width: 150, height: 36), fontSize: 11, alignment: .left, placeholder: ""),
                TemplateField(key: "lentorRow.hcStaffSignature", label: "HC Staff Sig", kind: .text, frame: CGRectCodable(x: 610, y: 290, width: 150, height: 36), fontSize: 11, alignment: .left, placeholder: "")
            ]
        )
    }
}
