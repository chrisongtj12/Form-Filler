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
    // Unified VM for Lentor (unused when showing LentorMedicalNotesFormView)
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
            if institution.institutionType == .activeGlobal {
                // Active Global unified screen
                activeGlobalView
            } else if institution.institutionType == .lentor {
                // Lentor unified screen
                lentorView
            } else {
                // Custom institution or institution with no type - show empty state
                emptyStateView
            }
        }
    }
    
    // MARK: - Active Global View
    
    private var activeGlobalView: some View {
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
    }
    
    // MARK: - Lentor View
    
    @State private var lentorPDFData: Data?
    @State private var showingLentorPreview = false
    @State private var showingLentorExport = false
    
    private var lentorView: some View {
        LentorFormScreen(
            lentorVM: lentorVM,
            patientNameMissing: lentorPatientMissing,
            clinicianMissing: lentorClinicianMissing,
            allNotesEmpty: lentorAllNotesEmpty,
            canExport: lentorCanExport,
            showingPasteParser: $showingLentorPasteParser,
            onTapCMR: {
                lentorPendingExport = .cmr
                lentorVM.lastExportChoice = .cmr
                exportLentorCMR()
            },
            onTapServiceAttendance: {
                lentorPendingExport = .serviceAttendance
                lentorVM.lastExportChoice = .serviceAttendance
                exportLentorServiceAttendance()
            }
        )
        .environmentObject(appState)
        .sheet(isPresented: $showingLentorPreview) {
            if let data = lentorPDFData {
                let filename = lentorExportFilename(for: lentorPendingExport)
                PDFPreviewView(pdfData: data, filename: filename, showingExport: $showingLentorExport)
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
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Forms Available")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("This institution doesn't have any forms configured yet.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            VStack(alignment: .leading, spacing: 12) {
                Label("Add a PDF template background", systemImage: "doc.badge.plus")
                Label("Configure form fields", systemImage: "slider.horizontal.3")
            }
            .font(.callout)
            .foregroundColor(.secondary)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            NavigationLink {
                TemplateEditorView()
                    .environmentObject(appState)
            } label: {
                Text("Open Template Editor")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.top, 10)
        }
        .padding()
        .navigationTitle(institution.displayName)
        .navigationBarTitleDisplayMode(.inline)
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
    
    private func lentorExportFilename(for choice: LentorFormViewModel.ExportChoice) -> String {
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
        
        // Map unified Lentor data to LentorMedicalNotesData
        let lmd = LentorMedicalNotesData(
            patientName: lentorVM.data.patientName,
            nric: lentorVM.data.nric,
            dateOfVisit: dateString,
            nokName: "",
            nokContact: "",
            temp: lentorVM.data.temp,
            rr: lentorVM.data.rr,
            bp: lentorVM.data.bp,
            spo2: lentorVM.data.spo2,
            pr: lentorVM.data.pr,
            hc: "",
            weightMostRecent: "",
            weightLeastRecent: "",
            gcIssue1: "",
            gcIssue2: "",
            gcIssue3: "",
            gcIssue4: "",
            gcIssue5: "",
            gcIssue6: "",
            gcIssue7: "",
            physicalExam: lentorVM.data.physicalExam,
            tcuPlan6m: "",
            docLabReportsChecked: false,
            docLabTrendChartFill: false,
            docLabTrendChartPresent: false,
            docMedRecRecon: false,
            docOthersText: "",
            planMedChanges: "",
            planLabTests: "",
            planSpecialMonitoring: "",
            planFollowUpReview: "",
            planReferralsMemos: "",
            planACP: "",
            planOthersUpdateNOK: lentorVM.data.plan,
            doctorName: lentorVM.data.clinicianName,
            doctorMCR: lentorVM.data.clinicianMCR,
            doctorESign: ""
        )
        
        let patient = Patient(name: lmd.patientName, nric: lmd.nric, dateOfBirth: nil)
        appState.saveLastPatient(patient)
        
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
                let text = lmd.value(for: field.key)
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
            alertMessage = "Could not load Lentor CMR form images."
            showingAlert = true
            return
        }
        
        let renderer = PDFRenderer()
        do {
            lentorPDFData = try renderer.render(pages: pages)
            showingLentorPreview = true
        } catch {
            alertMessage = "Failed to generate PDF: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func exportLentorServiceAttendance() {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy"
        let dateString = f.string(from: lentorVM.data.dateOfVisit)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        // Create a single row from current visit data
        let currentRow = LentorAttendanceRow(
            date: dateString,
            timeStart: "",
            timeEnd: "",
            totalHours: lentorVM.data.durationMins.isEmpty ? "" : String(format: "%.1f", (Double(lentorVM.data.durationMins) ?? 0) / 60.0),
            typeOfServices: lentorVM.data.interventions,
            caregiverSignature: "",
            hcStaffSignature: lentorVM.data.clinicianName
        )
        
        let hvData = LentorHVRecordData(
            clientName: lentorVM.data.patientName,
            clientNRIC: lentorVM.data.nric,
            serviceLocation: lentorVM.data.locationWard,
            serviceContact: "",
            caregiverName: "",
            caregiverNRIC: "",
            caregiverAddress: "",
            caregiverContact: "",
            rows: [currentRow]
        )
        
        let patient = Patient(name: hvData.clientName, nric: hvData.clientNRIC, dateOfBirth: nil)
        appState.saveLastPatient(patient)
        
        guard let template = appState.templates.first(where: { $0.backgroundImageName.contains("Lentor_HVRecord") }) else {
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
        
        // Header fields
        let headerFields = template.fields.filter { !$0.key.hasPrefix("lentorRow.") }
        for field in headerFields {
            let text = hvData.value(for: field.key)
            instructions.append(DrawInstruction(
                text: text,
                frame: field.frame.cgRect,
                fontSize: field.fontSize,
                alignment: field.alignment,
                isMultiline: field.kind == .multiline
            ))
        }
        
        // Row fields
        let rowFields = template.fields.filter { $0.key.hasPrefix("lentorRow.") }
        let rowHeight: CGFloat = 50
        
        for (rowIndex, row) in hvData.rows.enumerated() {
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
            lentorPDFData = try renderer.render(pages: [page])
            showingLentorPreview = true
        } catch {
            alertMessage = "Failed to generate PDF: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    // MARK: - Destination View (legacy; not used)
    
    @ViewBuilder
    private func destinationView(for form: FormDescriptor) -> some View {
        switch (form.institutionType, form.kind) {
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

#Preview {
    NavigationView {
        InstitutionFormListView(institution: .activeGlobal)
            .environmentObject(AppState())
    }
}
