//
//  InstitutionFormListView.swift
//  Speedoc Clinical Notes
//
//  List of forms for a specific institution
//

import SwiftUI
import Combine

// MARK: - Unified Active Global Form Model

struct ActiveGlobalFormData: Codable, Equatable {
    // Patient & visit
    var patientName: String = ""
    var nric: String = ""
    var dateOfVisit: Date = .now
    var clientOrNOK: String = ""
    
    // Vitals
    var bp: String = ""
    var spo2: String = ""
    var pr: String = ""
    var hypocount: String = ""
    
    // Notes
    var pastMedicalHistory: String = ""
    var presentingComplaint: String = ""
    var physicalExam: String = ""
    var diagnosisIssues: String = ""
    var managementPlan: String = ""
    
    // Clinician
    var clinicianName: String = ""
    var clinicianMCR: String = ""
}

// MARK: - View Model

final class ActiveGlobalFormViewModel: ObservableObject {
    @Published var data: ActiveGlobalFormData = ActiveGlobalFormData()
    
    private let storageKey = "ActiveGlobalFormData_unified"
    private let lastChoiceKey = "ActiveGlobalForm_lastExportChoice"
    
    @AppStorage("ActiveGlobalForm_lastExportChoice") var lastExportChoiceRaw: String = "medicalNotes"
    
    init() {
        load()
    }
    
    func reset() {
        data = ActiveGlobalFormData()
        save()
    }
    
    func load() {
        if let raw = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(ActiveGlobalFormData.self, from: raw) {
            data = decoded
        }
    }
    
    func save() {
        if let enc = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(enc, forKey: storageKey)
        }
    }
    
    enum ExportChoice: String {
        case medicalNotes
        case homeVisitRecord
    }
    
    var lastExportChoice: ExportChoice {
        get { ExportChoice(rawValue: lastExportChoiceRaw) ?? .medicalNotes }
        set { lastExportChoiceRaw = newValue.rawValue }
    }
}

// MARK: - Unified Lentor Form Model

struct LentorFormData: Codable, Equatable {
    // Patient & visit
    var patientName: String = ""
    var nric: String = ""
    var dateOfVisit: Date = .now
    var locationWard: String = ""        // ward/bed/room if applicable
    var serviceType: String = ""         // e.g., Home visit / Review

    // Vitals
    var bp: String = ""
    var pr: String = ""
    var spo2: String = ""
    var temp: String = ""
    var rr: String = ""

    // Clinical content
    var presentingComplaint: String = ""
    var historyOfPresentIllness: String = ""
    var pastMedicalHistory: String = ""
    var medicationList: String = ""
    var allergies: String = ""
    var physicalExam: String = ""

    // Assessment & Plan
    var assessment: String = ""          // issues/diagnoses
    var plan: String = ""                // management

    // Attendance / Service record specifics
    var visitReason: String = ""         // purpose of attendance
    var interventions: String = ""       // tasks done
    var durationMins: String = ""        // visit duration
    var nextReviewDate: Date? = nil

    // Clinician
    var clinicianName: String = ""
    var clinicianMCR: String = ""
}

final class LentorFormViewModel: ObservableObject {
    @Published var data: LentorFormData = LentorFormData()
    private let storageKey = "LentorFormData_unified"
    @AppStorage("LentorForm_lastExportChoice") var lastExportChoiceRaw: String = "cmr"
    
    enum ExportChoice: String {
        case cmr
        case serviceAttendance
    }
    
    var lastExportChoice: ExportChoice {
        get { ExportChoice(rawValue: lastExportChoiceRaw) ?? .cmr }
        set { lastExportChoiceRaw = newValue.rawValue }
    }
    
    init() {
        load()
    }
    
    func reset() {
        data = LentorFormData()
        save()
    }
    
    func load() {
        if let raw = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(LentorFormData.self, from: raw) {
            data = decoded
        }
    }
    
    func save() {
        if let enc = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(enc, forKey: storageKey)
        }
    }
}

// MARK: - Main View

struct InstitutionFormListView: View {
    @EnvironmentObject var appState: AppState
    let institution: Institution
    
    @State private var showingPasteParser = false
    @State private var showingLentorPasteParser = false
    
    // Unified VM for Active Global
    @StateObject private var agVM = ActiveGlobalFormViewModel()
    // Unified VM for Lentor
    @StateObject private var lentorVM = LentorFormViewModel()
    
    // Exporting state
    @State private var showDestinationPicker = false
    @State private var pendingExport: ActiveGlobalFormViewModel.ExportChoice = .medicalNotes
    @State private var lentorPendingExport: LentorFormViewModel.ExportChoice = .cmr
    @State private var showingPreview = false
    @State private var pdfData: Data?
    @State private var showingExport = false
    @State private var alertMessage = ""
    @State private var showingAlert = false
    
    // Menu
    @State private var showingMenu = false
    
    var body: some View {
        Group {
            if institution == .activeGlobal {
                ActiveGlobalFormScreen(
                    agVM: agVM,
                    patientNameMissing: patientNameMissing,
                    clinicianMissing: clinicianMissing,
                    allNotesEmpty: allNotesEmpty,
                    canExport: canExport,
                    showingPasteParser: $showingPasteParser,
                    showDestinationPicker: $showDestinationPicker,
                    onTapMedicalNotes: {
                        pendingExport = .medicalNotes
                        agVM.lastExportChoice = .medicalNotes
                        exportMedicalNotes()
                    },
                    onTapHomeVisit: {
                        pendingExport = .homeVisitRecord
                        agVM.lastExportChoice = .homeVisitRecord
                        exportHomeVisitRecord()
                    }
                )
                .environmentObject(appState)
                .sheet(isPresented: $showingPreview) {
                    if let data = pdfData {
                        let filename = exportFilename(for: pendingExport)
                        PDFPreviewView(pdfData: data, filename: filename, showingExport: $showingExport)
                    }
                }
                .sheet(isPresented: $showingPasteParser) {
                    PasteParseView()
                        .environmentObject(appState)
                        .onDisappear {
                            applyFromMedicalNotesDraftToUnified()
                        }
                }
                .alert("Error", isPresented: $showingAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(alertMessage)
                }
                .onAppear {
                    if agVM.data.clinicianName.isEmpty {
                        agVM.data.clinicianName = appState.clinician.displayName
                        agVM.data.clinicianMCR = appState.clinician.mcrNumber
                        agVM.save()
                    }
                    if agVM.data.patientName.isEmpty, let p = appState.lastUsedPatient {
                        agVM.data.patientName = p.name
                        agVM.data.nric = p.nric
                        agVM.save()
                    }
                }
            } else {
                LentorFormScreen(
                    lentorVM: lentorVM,
                    lentorPatientMissing: lentorPatientMissing,
                    lentorClinicianMissing: lentorClinicianMissing,
                    lentorAllNotesEmpty: lentorAllNotesEmpty,
                    lentorCanExport: lentorCanExport,
                    showingLentorPasteParser: $showingLentorPasteParser,
                    showDestinationPicker: $showDestinationPicker,
                    onTapCMR: {
                        lentorPendingExport = .cmr
                        lentorVM.lastExportChoice = .cmr
                        exportLentorCMR()
                    },
                    onTapServiceAttendance: {
                        if lentorVM.data.visitReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            lentorVM.data.interventions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            alertMessage = "Visit Reason and Interventions are recommended for Service Attendance Record."
                            showingAlert = true
                        }
                        lentorPendingExport = .serviceAttendance
                        lentorVM.lastExportChoice = .serviceAttendance
                        exportLentorServiceAttendance()
                    }
                )
                .environmentObject(appState)
                .sheet(isPresented: $showingPreview) {
                    if let data = pdfData {
                        let filename = exportFilenameLentor(for: lentorPendingExport)
                        PDFPreviewView(pdfData: data, filename: filename, showingExport: $showingExport)
                    }
                }
                .sheet(isPresented: $showingLentorPasteParser) {
                    LentorPasteParseView()
                        .environmentObject(appState)
                        .onDisappear {
                            applyFromLentorPasteToUnified()
                        }
                }
                .alert("Error", isPresented: $showingAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(alertMessage)
                }
                .onAppear {
                    if lentorVM.data.clinicianName.isEmpty {
                        lentorVM.data.clinicianName = appState.clinician.displayName
                        lentorVM.data.clinicianMCR = appState.clinician.mcrNumber
                        lentorVM.save()
                    }
                    if lentorVM.data.patientName.isEmpty, let p = appState.lastUsedPatient {
                        lentorVM.data.patientName = p.name
                        lentorVM.data.nric = p.nric
                        lentorVM.save()
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers (UI)
    
    private func characterCountEditor(title: String, text: Binding<String>, minHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            TextEditor(text: text)
                .frame(minHeight: minHeight)
            HStack {
                Spacer()
                Text("\(text.wrappedValue.count) chars")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Validation (Active Global)
    
    private var patientNameMissing: Bool {
        agVM.data.patientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    private var clinicianMissing: Bool {
        agVM.data.clinicianName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || agVM.data.clinicianMCR.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    private var allNotesEmpty: Bool {
        agVM.data.pastMedicalHistory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && agVM.data.presentingComplaint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && agVM.data.physicalExam.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && agVM.data.diagnosisIssues.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && agVM.data.managementPlan.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    private var canExport: Bool {
        !patientNameMissing && !clinicianMissing
    }
    
    // MARK: - Validation (Lentor)
    
    private var lentorPatientMissing: Bool {
        lentorVM.data.patientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    private var lentorClinicianMissing: Bool {
        lentorVM.data.clinicianName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || lentorVM.data.clinicianMCR.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    private var lentorAllNotesEmpty: Bool {
        lentorVM.data.presentingComplaint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && lentorVM.data.historyOfPresentIllness.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && lentorVM.data.pastMedicalHistory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && lentorVM.data.medicationList.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && lentorVM.data.allergies.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && lentorVM.data.physicalExam.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && lentorVM.data.assessment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && lentorVM.data.plan.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    private var lentorCanExport: Bool {
        !lentorPatientMissing && !lentorClinicianMissing
    }
    
    // MARK: - Paste Integration Bridge (Active Global)
    
    private func applyFromMedicalNotesDraftToUnified() {
        var unified = agVM.data
        let src = appState.medicalNotesDraft
        
        func take(_ new: String, into keyPath: WritableKeyPath<ActiveGlobalFormData, String>) {
            if unified[keyPath: keyPath].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               !new.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                unified[keyPath: keyPath] = new
            }
        }
        
        take(src.patientName, into: \.patientName)
        take(src.patientNRIC, into: \.nric)
        if unified.dateOfVisit == .distantPast || unified.dateOfVisit == .now || true {
            let f = DateFormatter()
            f.dateFormat = "dd/MM/yyyy"
            if let d = f.date(from: src.date), !src.date.isEmpty {
                unified.dateOfVisit = d
            }
        }
        take("", into: \.clientOrNOK)
        
        take(src.bp, into: \.bp)
        take(src.spo2, into: \.spo2)
        take(src.pr, into: \.pr)
        take(src.hypocount, into: \.hypocount)
        
        take(src.pastHistory, into: \.pastMedicalHistory)
        take(src.hpi, into: \.presentingComplaint)
        take(src.physicalExam, into: \.physicalExam)
        take(src.issues, into: \.diagnosisIssues)
        take(src.management, into: \.managementPlan)
        
        agVM.data = unified
        agVM.save()
    }
    
    // MARK: - Paste Integration Bridge (Lentor)
    
    private func applyFromLentorPasteToUnified() {
        var unified = lentorVM.data
        let src = appState.lentorMedicalNotesDraft
        
        func take(_ new: String, into keyPath: WritableKeyPath<LentorFormData, String>) {
            if unified[keyPath: keyPath].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               !new.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                unified[keyPath: keyPath] = new
            }
        }
        // Patient & visit
        take(src.patientName, into: \.patientName)
        take(src.nric, into: \.nric)
        let df = DateFormatter()
        df.dateFormat = "dd/MM/yyyy"
        if let d = df.date(from: src.dateOfVisit), !src.dateOfVisit.isEmpty {
            unified.dateOfVisit = d
        }
        // Vitals
        take(src.bp, into: \.bp)
        take(src.pr, into: \.pr)
        take(src.spo2, into: \.spo2)
        take(src.temp, into: \.temp)
        take(src.rr, into: \.rr)
        // Clinical
        take(src.physicalExam, into: \.physicalExam)
        // Assessment & Plan
        take(src.planOthersUpdateNOK, into: \.plan)
        // Clinician
        take(src.doctorName, into: \.clinicianName)
        take(src.doctorMCR, into: \.clinicianMCR)
        
        lentorVM.data = unified
        lentorVM.save()
    }
    
    // MARK: - Export (Active Global)
    
    private func exportFilename(for choice: ActiveGlobalFormViewModel.ExportChoice) -> String {
        let patient = agVM.data.patientName.isEmpty ? "Patient" : agVM.data.patientName
        switch choice {
        case .medicalNotes:
            if let desc = FormRegistry.shared.descriptor(institution: .activeGlobal, kind: .medicalNotes) {
                return desc.exportFilenameFormat.replacingOccurrences(of: "{PATIENT_NAME}", with: patient)
            }
            return "\(patient) Notes.pdf"
        case .homeVisitRecord:
            if let desc = FormRegistry.shared.descriptor(institution: .activeGlobal, kind: .homeVisitRecord) {
                return desc.exportFilenameFormat.replacingOccurrences(of: "{PATIENT_NAME}", with: patient)
            }
            return "\(patient) HV.pdf"
        }
    }
    
    private func exportMedicalNotes() {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy"
        let dateString = f.string(from: agVM.data.dateOfVisit)
        
        let md = MedicalNotesData(
            patientName: agVM.data.patientName,
            patientNRIC: agVM.data.nric,
            date: dateString,
            bp: agVM.data.bp,
            spo2: agVM.data.spo2,
            pr: agVM.data.pr,
            hypocount: agVM.data.hypocount,
            pastHistory: agVM.data.pastMedicalHistory,
            hpi: agVM.data.presentingComplaint,
            physicalExam: agVM.data.physicalExam,
            issues: agVM.data.diagnosisIssues,
            management: agVM.data.managementPlan,
            clinicianName: agVM.data.clinicianName,
            clinicianMCR: agVM.data.clinicianMCR
        )
        
        let patient = Patient(name: md.patientName, nric: md.patientNRIC, dateOfBirth: nil)
        appState.saveLastPatient(patient)
        
        let templates = appState.templates
            .filter { $0.backgroundImageName.contains("AG_MedicalNotes") }
            .sorted { $0.pageIndex < $1.pageIndex }
        
        guard !templates.isEmpty else {
            alertMessage = "Medical notes templates not found. Please check Settings."
            showingAlert = true
            return
        }
        
        let pages: [RenderedPage] = templates.compactMap { template in
            guard let image = PlatformImage.load(named: template.backgroundImageName) else { return nil }
            let instructions = template.fields.map { field -> DrawInstruction in
                let text = md.value(for: field.key)
                return DrawInstruction(
                    text: text,
                    frame: field.frame.cgRect,
                    fontSize: field.fontSize,
                    alignment: field.alignment,
                    isMultiline: field.kind == .multiline
                )
            }
            return RenderedPage(backgroundImage: image, instructions: instructions)
        }
        
        guard !pages.isEmpty else {
            alertMessage = "Could not load form images. Please add AG_MedicalNotes_p1 and AG_MedicalNotes_p2 to Assets."
            showingAlert = true
            return
        }
        
        let renderer = PDFRenderer()
        do {
            pdfData = try renderer.render(pages: pages)
            showingPreview = true
        } catch {
            alertMessage = "Failed to generate PDF: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func exportHomeVisitRecord() {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy"
        let dateString = f.string(from: agVM.data.dateOfVisit)
        
        let hvHeader = HVRecordData(serviceType: "Home Medical", clinicianName: agVM.data.clinicianName, rows: [])
        
        let currentVisitRow = HVRecordRow(
            clientName: agVM.data.patientName,
            clientNRIC: agVM.data.nric,
            dateTimeOfVisit: dateString,
            clientNOK: agVM.data.clientOrNOK,
            signatureText: ""
        )
        
        guard let template = appState.templates.first(where: { $0.backgroundImageName.contains("AG_HomeVisitRecord") }) else {
            alertMessage = "Home Visit Record template not found. Please check Settings."
            showingAlert = true
            return
        }
        guard let image = PlatformImage.load(named: template.backgroundImageName) else {
            alertMessage = "Could not load form image. Please add AG_HomeVisitRecord to Assets."
            showingAlert = true
            return
        }
        
        var instructions: [DrawInstruction] = []
        
        for field in template.fields where field.key.hasPrefix("hv.") {
            var text = hvHeader.value(for: field.key)
            if field.key == "hv.clinicianName", text.isEmpty {
                text = agVM.data.clinicianName
            }
            instructions.append(DrawInstruction(
                text: text,
                frame: field.frame.cgRect,
                fontSize: field.fontSize,
                alignment: field.alignment,
                isMultiline: field.kind == .multiline
            ))
        }
        
        let rowFields = template.fields.filter { $0.key.hasPrefix("row.") }
        let rowHeight: CGFloat = 50
        
        let allRows = [currentVisitRow] + appState.hvRecordDraft.rows
        for (rowIndex, row) in allRows.enumerated() {
            let yOffset = CGFloat(rowIndex) * rowHeight
            for field in rowFields {
                let text = row.value(for: field.key)
                var adjustedFrame = field.frame.cgRect
                adjustedFrame.origin.y += yOffset
                instructions.append(DrawInstruction(
                    text: text,
                    frame: adjustedFrame,
                    fontSize: field.fontSize,
                    alignment: field.alignment,
                    isMultiline: false
                ))
            }
        }
        
        let page = RenderedPage(backgroundImage: image, instructions: instructions)
        let renderer = PDFRenderer()
        do {
            pdfData = try renderer.render(pages: [page])
            showingPreview = true
        } catch {
            alertMessage = "Failed to generate PDF: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    // MARK: - Export (Lentor)
    
    private func exportFilenameLentor(for choice: LentorFormViewModel.ExportChoice) -> String {
        let patient = lentorVM.data.patientName.isEmpty ? "Patient" : lentorVM.data.patientName
        switch choice {
        case .cmr:
            if let desc = FormRegistry.shared.descriptor(institution: .lentor, kind: .medicalNotes) {
                return desc.exportFilenameFormat.replacingOccurrences(of: "{PATIENT_NAME}", with: patient)
            }
            return "\(patient) Lentor Notes.pdf"
        case .serviceAttendance:
            if let desc = FormRegistry.shared.descriptor(institution: .lentor, kind: .homeVisitRecord) {
                return desc.exportFilenameFormat.replacingOccurrences(of: "{PATIENT_NAME}", with: patient)
            }
            return "\(patient) Lentor HV.pdf"
        }
    }
    
    private func exportLentorCMR() {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy"
        let dateString = f.string(from: lentorVM.data.dateOfVisit)
        
        var cmr = LentorMedicalNotesData()
        cmr.patientName = lentorVM.data.patientName
        cmr.nric = lentorVM.data.nric
        cmr.dateOfVisit = dateString
        cmr.bp = lentorVM.data.bp
        cmr.pr = lentorVM.data.pr
        cmr.spo2 = lentorVM.data.spo2
        cmr.temp = lentorVM.data.temp
        cmr.rr = lentorVM.data.rr
        cmr.physicalExam = lentorVM.data.physicalExam
        cmr.planOthersUpdateNOK = lentorVM.data.plan
        cmr.doctorName = lentorVM.data.clinicianName
        cmr.doctorMCR = lentorVM.data.clinicianMCR
        
        let templates = appState.templates
            .filter { $0.backgroundImageName.contains("Lentor_MedicalNotes") }
            .sorted { $0.pageIndex < $1.pageIndex }
        
        guard !templates.isEmpty else {
            alertMessage = "Lentor CMR templates not found. Please check Settings."
            showingAlert = true
            return
        }
        
        let pages: [RenderedPage] = templates.compactMap { template in
            guard let image = PlatformImage.load(named: template.backgroundImageName) else { return nil }
            let instructions = template.fields.map { field -> DrawInstruction in
                let text = cmr.value(for: field.key)
                return DrawInstruction(
                    text: text,
                    frame: field.frame.cgRect,
                    fontSize: field.fontSize,
                    alignment: field.alignment,
                    isMultiline: field.kind == .multiline
                )
            }
            return RenderedPage(backgroundImage: image, instructions: instructions)
        }
        
        let renderer = PDFRenderer()
        do {
            pdfData = try renderer.render(pages: pages)
            showingPreview = true
        } catch {
            alertMessage = "Failed to generate PDF: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func exportLentorServiceAttendance() {
        var hv = LentorHVRecordData()
        hv.clientName = lentorVM.data.patientName
        hv.clientNRIC = lentorVM.data.nric
        hv.serviceLocation = lentorVM.data.locationWard
        hv.serviceContact = ""
        hv.caregiverName = ""
        hv.caregiverNRIC = ""
        hv.caregiverAddress = ""
        hv.caregiverContact = ""
        
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy"
        let dateString = f.string(from: lentorVM.data.dateOfVisit)
        
        let duration = lentorVM.data.durationMins
        let row = LentorAttendanceRow(
            date: dateString,
            timeStart: "",
            timeEnd: "",
            totalHours: duration,
            typeOfServices: lentorVM.data.serviceType,
            caregiverSignature: "",
            hcStaffSignature: lentorVM.data.clinicianName
        )
        hv.rows = [row] + appState.lentorHVRecordDraft.rows
        
        guard let template = appState.templates.first(where: { $0.backgroundImageName.contains("Lentor_ServiceAttendance") }) else {
            alertMessage = "Lentor Service Attendance template not found. Please check Settings."
            showingAlert = true
            return
        }
        guard let image = PlatformImage.load(named: template.backgroundImageName) else {
            alertMessage = "Could not load Lentor Service Attendance image."
            showingAlert = true
            return
        }
        
        var instructions: [DrawInstruction] = []
        for field in template.fields where field.key.hasPrefix("lentorHV.") {
            let text = hv.value(for: field.key)
            instructions.append(DrawInstruction(
                text: text,
                frame: field.frame.cgRect,
                fontSize: field.fontSize,
                alignment: field.alignment,
                isMultiline: field.kind == .multiline
            ))
        }
        let rowFields = template.fields.filter { $0.key.hasPrefix("lentorRow.") }
        let rowHeight: CGFloat = 40
        for (idx, r) in hv.rows.enumerated() {
            let yOffset = CGFloat(idx) * rowHeight
            for field in rowFields {
                let text = r.value(for: field.key)
                var frame = field.frame.cgRect
                frame.origin.y += yOffset
                instructions.append(DrawInstruction(
                    text: text,
                    frame: frame,
                    fontSize: field.fontSize,
                    alignment: field.alignment,
                    isMultiline: false
                ))
            }
        }
        
        let page = RenderedPage(backgroundImage: image, instructions: instructions)
        let renderer = PDFRenderer()
        do {
            pdfData = try renderer.render(pages: [page])
            showingPreview = true
        } catch {
            alertMessage = "Failed to generate PDF: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    // MARK: - Destination View (legacy; not used)
    
    @ViewBuilder
    private func destinationView(for form: FormDescriptor) -> some View {
        switch (form.institution, form.kind) {
        case (.activeGlobal, .medicalNotes):
            MedicalNotesFormView()
        case (.activeGlobal, .homeVisitRecord):
            HVRecordFormView()
        case (.lentor, .medicalNotes):
            LentorMedicalNotesFormView()
        case (.lentor, .homeVisitRecord):
            LentorHVRecordFormView()
        }
    }
}

// MARK: - Extracted Screens

private struct ActiveGlobalFormScreen: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var agVM: ActiveGlobalFormViewModel
    
    let patientNameMissing: Bool
    let clinicianMissing: Bool
    let allNotesEmpty: Bool
    let canExport: Bool
    
    @Binding var showingPasteParser: Bool
    @Binding var showDestinationPicker: Bool
    
    let onTapMedicalNotes: () -> Void
    let onTapHomeVisit: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    Button(action: { showingPasteParser = true }) {
                        HStack {
                            Image(systemName: "doc.on.clipboard.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("Paste AVIXO Template")
                                    .fontWeight(.semibold)
                                Text("Auto-fill from copied text")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Patient & Visit")) {
                    let patientBinding = Binding(
                        get: { agVM.data.patientName },
                        set: { agVM.data.patientName = $0; agVM.save() }
                    )
                    let nricBinding = Binding(
                        get: { agVM.data.nric },
                        set: { agVM.data.nric = $0; agVM.save() }
                    )
                    let dateBinding = Binding(
                        get: { agVM.data.dateOfVisit },
                        set: { agVM.data.dateOfVisit = $0; agVM.save() }
                    )
                    let clientBinding = Binding(
                        get: { agVM.data.clientOrNOK },
                        set: { agVM.data.clientOrNOK = $0; agVM.save() }
                    )
                    
                    TextField("Patient Name", text: patientBinding)
                        .textContentType(.name)
                    TextField("NRIC", text: nricBinding)
                        .textContentType(.username)
                    DatePicker("Date of Visit", selection: dateBinding, displayedComponents: [.date])
                    TextField("Client / NOK", text: clientBinding)
                    
                    if patientNameMissing {
                        Text("Patient name is required").font(.footnote).foregroundColor(.red)
                    }
                    if clinicianMissing {
                        Text("Clinician name and MCR are required").font(.footnote).foregroundColor(.red)
                    }
                }
                
                Section(header: Text("Vitals")) {
                    let bpBinding = Binding(
                        get: { agVM.data.bp },
                        set: { agVM.data.bp = $0; agVM.save() }
                    )
                    let spo2Binding = Binding(
                        get: { agVM.data.spo2 },
                        set: { agVM.data.spo2 = $0; agVM.save() }
                    )
                    let prBinding = Binding(
                        get: { agVM.data.pr },
                        set: { agVM.data.pr = $0; agVM.save() }
                    )
                    let hypoBinding = Binding(
                        get: { agVM.data.hypocount },
                        set: { agVM.data.hypocount = $0; agVM.save() }
                    )
                    
                    TextField("BP", text: bpBinding)
                    TextField("SpO2", text: spo2Binding)
                    TextField("PR", text: prBinding)
                    TextField("Hypocount", text: hypoBinding)
                }
                
                Section(header: Text("History & Examination")) {
                    characterCountEditor(title: "Past Medical History",
                                         text: Binding(get: { agVM.data.pastMedicalHistory },
                                                       set: { agVM.data.pastMedicalHistory = $0; agVM.save() }),
                                         minHeight: 100)
                    
                    characterCountEditor(title: "Presenting Complaint",
                                         text: Binding(get: { agVM.data.presentingComplaint },
                                                       set: { agVM.data.presentingComplaint = $0; agVM.save() }),
                                         minHeight: 120)
                    
                    characterCountEditor(title: "Physical Examination",
                                         text: Binding(get: { agVM.data.physicalExam },
                                                       set: { agVM.data.physicalExam = $0; agVM.save() }),
                                         minHeight: 120)
                }
                
                Section(header: Text("Assessment & Plan")) {
                    characterCountEditor(title: "Issues / Diagnosis",
                                         text: Binding(get: { agVM.data.diagnosisIssues },
                                                       set: { agVM.data.diagnosisIssues = $0; agVM.save() }),
                                         minHeight: 100)
                    
                    characterCountEditor(title: "Management / Plan",
                                         text: Binding(get: { agVM.data.managementPlan },
                                                       set: { agVM.data.managementPlan = $0; agVM.save() }),
                                         minHeight: 120)
                    
                    if allNotesEmpty {
                        Text("Warning: All note fields are empty")
                            .font(.footnote)
                            .foregroundColor(.orange)
                    }
                }
                
                Section(header: Text("Clinician")) {
                    let clinicianNameBinding = Binding(
                        get: { agVM.data.clinicianName },
                        set: { agVM.data.clinicianName = $0; agVM.save() }
                    )
                    let clinicianMCRBinding = Binding(
                        get: { agVM.data.clinicianMCR },
                        set: { agVM.data.clinicianMCR = $0; agVM.save() }
                    )
                    
                    TextField("Clinician Name", text: clinicianNameBinding)
                    TextField("MCR Number", text: clinicianMCRBinding)
                    
                    Button("Use My Profile") {
                        agVM.data.clinicianName = appState.clinician.displayName
                        agVM.data.clinicianMCR = appState.clinician.mcrNumber
                        agVM.save()
                    }
                }
            }
            
            VStack(spacing: 0) {
                Divider()
                HStack {
                    Menu {
                        Button("Reset Form", role: .destructive) {
                            agVM.reset()
                        }
                        Button("Load Last") {
                            agVM.load()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .imageScale(.large)
                            .padding(.horizontal)
                    }
                    
                    Button(action: {
                        showDestinationPicker = true
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.down.doc.fill")
                            Text("Preview & Export")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding()
                        .background(canExport ? Color.accentColor : Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!canExport)
                    .padding(.vertical, 8)
                    .padding(.trailing)
                }
                .padding(.bottom, 6)
                .background(
                    Group {
                        #if os(iOS)
                        Color(UIColor.systemBackground)
                        #elseif os(macOS)
                        Color(nsColor: .windowBackgroundColor)
                        #endif
                    }
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: -2)
                )
            }
        }
        .navigationTitle(Institution.activeGlobal.displayName)
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog("Choose Output", isPresented: $showDestinationPicker, titleVisibility: .visible) {
            Button("Medical Notes", action: onTapMedicalNotes)
            Button("Home Visit Record", action: onTapHomeVisit)
            Button("Cancel", role: .cancel) {}
        }
    }
    
    private func characterCountEditor(title: String, text: Binding<String>, minHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            TextEditor(text: text)
                .frame(minHeight: minHeight)
            HStack {
                Spacer()
                Text("\(text.wrappedValue.count) chars")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct LentorFormScreen: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var lentorVM: LentorFormViewModel
    
    let lentorPatientMissing: Bool
    let lentorClinicianMissing: Bool
    let lentorAllNotesEmpty: Bool
    let lentorCanExport: Bool
    
    @Binding var showingLentorPasteParser: Bool
    @Binding var showDestinationPicker: Bool
    
    let onTapCMR: () -> Void
    let onTapServiceAttendance: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    Button(action: { showingLentorPasteParser = true }) {
                        HStack {
                            Image(systemName: "doc.on.clipboard.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("Paste Lentor Template")
                                    .fontWeight(.semibold)
                                Text("Auto-fill from copied text")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Patient & Visit")) {
                    let patientBinding = Binding(
                        get: { lentorVM.data.patientName },
                        set: { lentorVM.data.patientName = $0; lentorVM.save() }
                    )
                    let nricBinding = Binding(
                        get: { lentorVM.data.nric },
                        set: { lentorVM.data.nric = $0; lentorVM.save() }
                    )
                    let dateBinding = Binding(
                        get: { lentorVM.data.dateOfVisit },
                        set: { lentorVM.data.dateOfVisit = $0; lentorVM.save() }
                    )
                    let locationBinding = Binding(
                        get: { lentorVM.data.locationWard },
                        set: { lentorVM.data.locationWard = $0; lentorVM.save() }
                    )
                    let serviceBinding = Binding(
                        get: { lentorVM.data.serviceType },
                        set: { lentorVM.data.serviceType = $0; lentorVM.save() }
                    )
                    
                    TextField("Patient Name", text: patientBinding)
                        .textContentType(.name)
                    TextField("NRIC", text: nricBinding)
                    DatePicker("Date of Visit", selection: dateBinding, displayedComponents: [.date])
                    TextField("Location / Ward", text: locationBinding)
                    TextField("Service Type", text: serviceBinding)
                    
                    if lentorPatientMissing {
                        Text("Patient name is required").font(.footnote).foregroundColor(.red)
                    }
                    if lentorClinicianMissing {
                        Text("Clinician name and MCR are required").font(.footnote).foregroundColor(.red)
                    }
                }
                
                Section(header: Text("Vitals")) {
                    let bpBinding = Binding(
                        get: { lentorVM.data.bp },
                        set: { lentorVM.data.bp = $0; lentorVM.save() }
                    )
                    let prBinding = Binding(
                        get: { lentorVM.data.pr },
                        set: { lentorVM.data.pr = $0; lentorVM.save() }
                    )
                    let spo2Binding = Binding(
                        get: { lentorVM.data.spo2 },
                        set: { lentorVM.data.spo2 = $0; lentorVM.save() }
                    )
                    let tempBinding = Binding(
                        get: { lentorVM.data.temp },
                        set: { lentorVM.data.temp = $0; lentorVM.save() }
                    )
                    let rrBinding = Binding(
                        get: { lentorVM.data.rr },
                        set: { lentorVM.data.rr = $0; lentorVM.save() }
                    )
                    
                    TextField("BP", text: bpBinding)
                    TextField("PR", text: prBinding)
                    TextField("SpO2", text: spo2Binding)
                    TextField("Temp", text: tempBinding)
                    TextField("RR", text: rrBinding)
                }
                
                Section(header: Text("Clinical Notes")) {
                    characterCountEditor(title: "Presenting Complaint",
                                         text: Binding(get: { lentorVM.data.presentingComplaint },
                                                       set: { lentorVM.data.presentingComplaint = $0; lentorVM.save() }),
                                         minHeight: 80)
                    characterCountEditor(title: "History of Present Illness",
                                         text: Binding(get: { lentorVM.data.historyOfPresentIllness },
                                                       set: { lentorVM.data.historyOfPresentIllness = $0; lentorVM.save() }),
                                         minHeight: 100)
                    characterCountEditor(title: "Past Medical History",
                                         text: Binding(get: { lentorVM.data.pastMedicalHistory },
                                                       set: { lentorVM.data.pastMedicalHistory = $0; lentorVM.save() }),
                                         minHeight: 80)
                    characterCountEditor(title: "Medication List",
                                         text: Binding(get: { lentorVM.data.medicationList },
                                                       set: { lentorVM.data.medicationList = $0; lentorVM.save() }),
                                         minHeight: 80)
                    characterCountEditor(title: "Allergies",
                                         text: Binding(get: { lentorVM.data.allergies },
                                                       set: { lentorVM.data.allergies = $0; lentorVM.save() }),
                                         minHeight: 60)
                    characterCountEditor(title: "Physical Examination",
                                         text: Binding(get: { lentorVM.data.physicalExam },
                                                       set: { lentorVM.data.physicalExam = $0; lentorVM.save() }),
                                         minHeight: 100)
                    
                    if lentorAllNotesEmpty {
                        Text("Warning: All clinical note fields are empty")
                            .font(.footnote)
                            .foregroundColor(.orange)
                    }
                }
                
                Section(header: Text("Assessment & Plan")) {
                    characterCountEditor(title: "Assessment (Issues / Diagnoses)",
                                         text: Binding(get: { lentorVM.data.assessment },
                                                       set: { lentorVM.data.assessment = $0; lentorVM.save() }),
                                         minHeight: 100)
                    characterCountEditor(title: "Plan (Management)",
                                         text: Binding(get: { lentorVM.data.plan },
                                                       set: { lentorVM.data.plan = $0; lentorVM.save() }),
                                         minHeight: 100)
                }
                
                Section(header: Text("Attendance / Service Record")) {
                    characterCountEditor(title: "Visit Reason",
                                         text: Binding(get: { lentorVM.data.visitReason },
                                                       set: { lentorVM.data.visitReason = $0; lentorVM.save() }),
                                         minHeight: 60)
                    characterCountEditor(title: "Interventions / Tasks Done",
                                         text: Binding(get: { lentorVM.data.interventions },
                                                       set: { lentorVM.data.interventions = $0; lentorVM.save() }),
                                         minHeight: 80)
                    TextField("Duration (mins)", text: Binding(
                        get: { lentorVM.data.durationMins },
                        set: { lentorVM.data.durationMins = $0; lentorVM.save() }
                    ))
                    DatePicker("Next Review Date", selection: Binding(
                        get: { lentorVM.data.nextReviewDate ?? Date() },
                        set: { lentorVM.data.nextReviewDate = $0; lentorVM.save() }
                    ), displayedComponents: [.date])
                }
                
                Section(header: Text("Clinician")) {
                    let clinicianNameBinding = Binding(
                        get: { lentorVM.data.clinicianName },
                        set: { lentorVM.data.clinicianName = $0; lentorVM.save() }
                    )
                    let clinicianMCRBinding = Binding(
                        get: { lentorVM.data.clinicianMCR },
                        set: { lentorVM.data.clinicianMCR = $0; lentorVM.save() }
                    )
                    TextField("Clinician Name", text: clinicianNameBinding)
                    TextField("MCR Number", text: clinicianMCRBinding)
                    Button("Use My Profile") {
                        lentorVM.data.clinicianName = appState.clinician.displayName
                        lentorVM.data.clinicianMCR = appState.clinician.mcrNumber
                        lentorVM.save()
                    }
                }
            }
            
            VStack(spacing: 0) {
                Divider()
                HStack {
                    Menu {
                        Button("Reset Form", role: .destructive) {
                            lentorVM.reset()
                        }
                        Button("Load Last") {
                            lentorVM.load()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .imageScale(.large)
                            .padding(.horizontal)
                    }
                    
                    Button(action: {
                        if !lentorCanExport {
                            // Alert handled at parent level (we don’t have direct bindings here)
                            // But we keep button disabled visually too.
                        }
                        showDestinationPicker = true
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.down.doc.fill")
                            Text("Preview & Export")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding()
                        .background(lentorCanExport ? Color.accentColor : Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!lentorCanExport)
                    .padding(.vertical, 8)
                    .padding(.trailing)
                }
                .padding(.bottom, 6)
                .background(
                    Group {
                        #if os(iOS)
                        Color(UIColor.systemBackground)
                        #elseif os(macOS)
                        Color(nsColor: .windowBackgroundColor)
                        #endif
                    }
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: -2)
                )
            }
        }
        .navigationTitle(Institution.lentor.displayName)
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog("Choose Output", isPresented: $showDestinationPicker, titleVisibility: .visible) {
            Button("Export Chronic Medical Review", action: onTapCMR)
            Button("Export Service Attendance Record", action: onTapServiceAttendance)
            Button("Cancel", role: .cancel) {}
        }
    }
    
    private func characterCountEditor(title: String, text: Binding<String>, minHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            TextEditor(text: text)
                .frame(minHeight: minHeight)
            HStack {
                Spacer()
                Text("\(text.wrappedValue.count) chars")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    NavigationView {
        InstitutionFormListView(institution: .activeGlobal)
            .environmentObject(AppState())
    }
}
