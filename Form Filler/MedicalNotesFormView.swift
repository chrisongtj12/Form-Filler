//
//  MedicalNotesFormView.swift
//  Speedoc Clinical Notes
//
//  Form for filling out Active Global Medical Notes
//

import SwiftUI

struct MedicalNotesFormView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var showingPreview = false
    @State private var showingExport = false
    @State private var pdfData: Data?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingPasteParser = false
    
    // New state to choose which output
    @State private var showDestinationPicker = false
    enum ExportDestination {
        case medicalNotes
        case homeVisitRecord
    }
    @State private var pendingDestination: ExportDestination = .medicalNotes
    
    var body: some View {
        Form {
            // Quick Actions Section
            Section {
                Button(action: {
                    showingPasteParser = true
                }) {
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
            
            Section(header: Text("Patient Information")) {
                TextField("Patient Name", text: $appState.medicalNotesDraft.patientName)
                    .onChange(of: appState.medicalNotesDraft.patientName) {
                        appState.saveMedicalNotesDraft()
                    }
                
                TextField("NRIC", text: $appState.medicalNotesDraft.patientNRIC)
                    .onChange(of: appState.medicalNotesDraft.patientNRIC) {
                        appState.saveMedicalNotesDraft()
                    }
                
                TextField("Date", text: $appState.medicalNotesDraft.date)
                    .onChange(of: appState.medicalNotesDraft.date) {
                        appState.saveMedicalNotesDraft()
                    }
                
                Button("Use Last Patient") {
                    if let patient = appState.lastUsedPatient {
                        appState.medicalNotesDraft.patientName = patient.name
                        appState.medicalNotesDraft.patientNRIC = patient.nric
                        appState.saveMedicalNotesDraft()
                    }
                }
                .disabled(appState.lastUsedPatient == nil)
                
                Button("Set Today's Date") {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd/MM/yyyy"
                    appState.medicalNotesDraft.date = formatter.string(from: Date())
                    appState.saveMedicalNotesDraft()
                }
            }
            
            Section(header: Text("Vital Signs")) {
                TextField("Blood Pressure (BP)", text: $appState.medicalNotesDraft.bp)
                    .onChange(of: appState.medicalNotesDraft.bp) {
                        appState.saveMedicalNotesDraft()
                    }
                
                TextField("SpO2", text: $appState.medicalNotesDraft.spo2)
                    .onChange(of: appState.medicalNotesDraft.spo2) {
                        appState.saveMedicalNotesDraft()
                    }
                
                TextField("Pulse Rate (PR)", text: $appState.medicalNotesDraft.pr)
                    .onChange(of: appState.medicalNotesDraft.pr) {
                        appState.saveMedicalNotesDraft()
                    }
                
                TextField("Hypo Count", text: $appState.medicalNotesDraft.hypocount)
                    .onChange(of: appState.medicalNotesDraft.hypocount) {
                        appState.saveMedicalNotesDraft()
                    }
            }
            
            Section(header: Text("Medical History & Examination")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Past Medical History")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $appState.medicalNotesDraft.pastHistory)
                        .frame(height: 100)
                        .onChange(of: appState.medicalNotesDraft.pastHistory) {
                            appState.saveMedicalNotesDraft()
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("History of Presenting Complaint")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $appState.medicalNotesDraft.hpi)
                        .frame(height: 120)
                        .onChange(of: appState.medicalNotesDraft.hpi) {
                            appState.saveMedicalNotesDraft()
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Physical Examination")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $appState.medicalNotesDraft.physicalExam)
                        .frame(height: 120)
                        .onChange(of: appState.medicalNotesDraft.physicalExam) {
                            appState.saveMedicalNotesDraft()
                        }
                }
            }
            
            Section(header: Text("Assessment & Plan")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Issues / Diagnosis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $appState.medicalNotesDraft.issues)
                        .frame(height: 100)
                        .onChange(of: appState.medicalNotesDraft.issues) {
                            appState.saveMedicalNotesDraft()
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Management / Plan")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $appState.medicalNotesDraft.management)
                        .frame(height: 120)
                        .onChange(of: appState.medicalNotesDraft.management) {
                            appState.saveMedicalNotesDraft()
                        }
                }
            }
            
            Section(header: Text("Clinician")) {
                TextField("Clinician Name", text: $appState.medicalNotesDraft.clinicianName)
                    .onChange(of: appState.medicalNotesDraft.clinicianName) {
                        appState.saveMedicalNotesDraft()
                    }
                
                TextField("MCR Number", text: $appState.medicalNotesDraft.clinicianMCR)
                    .onChange(of: appState.medicalNotesDraft.clinicianMCR) {
                        appState.saveMedicalNotesDraft()
                    }
                
                Button("Use My Profile") {
                    appState.medicalNotesDraft.clinicianName = appState.clinician.displayName
                    appState.medicalNotesDraft.clinicianMCR = appState.clinician.mcrNumber
                    appState.saveMedicalNotesDraft()
                }
            }
            
            Section {
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
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Medical Notes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            autoFillIfEmpty()
        }
        .confirmationDialog("Choose Output", isPresented: $showDestinationPicker, titleVisibility: .visible) {
            Button("Medical Notes") {
                pendingDestination = .medicalNotes
                generatePDF(for: .medicalNotes)
            }
            Button("Home Visit Record") {
                pendingDestination = .homeVisitRecord
                generatePDF(for: .homeVisitRecord)
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingPreview) {
            Group {
                if let data = pdfData {
                    let filename: String = {
                        let rawName = appState.medicalNotesDraft.patientName.isEmpty ? "Unknown" : appState.medicalNotesDraft.patientName
                        let patientName = sanitizeFilename(rawName)
                        switch pendingDestination {
                        case .medicalNotes:
                            return "\(patientName) Notes.pdf"
                        case .homeVisitRecord:
                            return "\(patientName) HV.pdf"
                        }
                    }()
                    
                    PDFPreviewView(
                        pdfData: data,
                        filename: filename,
                        showingExport: $showingExport
                    )
                } else {
                    EmptyView()
                }
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingPasteParser) {
            PasteParseView()
        }
    }
    
    private func autoFillIfEmpty() {
        if appState.medicalNotesDraft.patientName.isEmpty,
           let patient = appState.lastUsedPatient {
            appState.medicalNotesDraft.patientName = patient.name
            appState.medicalNotesDraft.patientNRIC = patient.nric
        }
        
        if appState.medicalNotesDraft.date.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            appState.medicalNotesDraft.date = formatter.string(from: Date())
        }
        
        if appState.medicalNotesDraft.clinicianName.isEmpty {
            appState.medicalNotesDraft.clinicianName = appState.clinician.displayName
            appState.medicalNotesDraft.clinicianMCR = appState.clinician.mcrNumber
        }
        
        appState.saveMedicalNotesDraft()
    }
    
    private func generatePDF(for destination: ExportDestination) {
        switch destination {
        case .medicalNotes:
            generateMedicalNotesPDF()
        case .homeVisitRecord:
            generateHVRecordPDF()
        }
    }
    
    private func generateMedicalNotesPDF() {
        guard !appState.medicalNotesDraft.patientName.isEmpty else {
            alertMessage = "Please enter a patient name before exporting."
            showingAlert = true
            return
        }
        
        // Save patient for next time
        let patient = Patient(
            name: appState.medicalNotesDraft.patientName,
            nric: appState.medicalNotesDraft.patientNRIC,
            dateOfBirth: nil
        )
        appState.saveLastPatient(patient)
        
        // Get templates
        let templates = appState.templates.filter {
            $0.backgroundImageName.contains("AG_MedicalNotes")
        }.sorted { $0.pageIndex < $1.pageIndex }
        
        guard !templates.isEmpty else {
            alertMessage = "Medical notes templates not found. Please check Settings."
            showingAlert = true
            return
        }
        
        // Generate PDF
        let renderer = PDFRenderer()
        let pages = templates.compactMap { template -> RenderedPage? in
            guard let image = PlatformImage.load(named: template.backgroundImageName) else {
                return nil
            }
            
            let instructions = template.fields.map { field -> DrawInstruction in
                let text = appState.medicalNotesDraft.value(for: field.key)
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
        
        do {
            pdfData = try renderer.render(pages: pages)
            showingPreview = true
        } catch {
            alertMessage = "Failed to generate PDF: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func generateHVRecordPDF() {
        guard !appState.medicalNotesDraft.patientName.isEmpty else {
            alertMessage = "Please enter a patient name before exporting."
            showingAlert = true
            return
        }
        
        guard let template = appState.templates.first(where: {
            $0.backgroundImageName.contains("AG_HomeVisitRecord")
        }) else {
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
        
        // Header fields
        for field in template.fields {
            if field.key.starts(with: "hv.") {
                var text = appState.hvRecordDraft.value(for: field.key)
                if field.key == "hv.clinicianName" && text.isEmpty {
                    text = appState.medicalNotesDraft.clinicianName
                }
                instructions.append(DrawInstruction(
                    text: text,
                    frame: field.frame.cgRect,
                    fontSize: field.fontSize,
                    alignment: field.alignment,
                    isMultiline: false
                ))
            }
        }
        
        // Current visit + draft rows
        let currentVisitRow = HVRecordRow(
            clientName: appState.medicalNotesDraft.patientName,
            clientNRIC: appState.medicalNotesDraft.patientNRIC,
            dateTimeOfVisit: appState.medicalNotesDraft.date,
            clientNOK: "",
            signatureText: ""
        )
        let allRows = [currentVisitRow] + appState.hvRecordDraft.rows
        
        let rowFields = template.fields.filter { $0.key.starts(with: "row.") }
        let rowHeight: CGFloat = 50
        
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
    
    // MARK: - Filename Sanitizer
    
    private func sanitizeFilename(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        // Disallowed on most filesystems: / \ ? % * : | " < >
        let illegal = CharacterSet(charactersIn: "/\\?%*:|\"<>")
        let components = trimmed.components(separatedBy: illegal)
        let collapsed = components.filter { !$0.isEmpty }.joined(separator: " ")
        // Also collapse repeated spaces
        let normalized = collapsed.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return normalized.isEmpty ? "Unknown" : normalized
    }
}

#Preview {
    NavigationView {
        MedicalNotesFormView()
            .environmentObject(AppState())
    }
}
