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
    
    var body: some View {
        Form {
            Section(header: Text("Patient Information")) {
                TextField("Patient Name", text: $appState.medicalNotesDraft.patientName)
                    .onChange(of: appState.medicalNotesDraft.patientName) { _ in
                        appState.saveMedicalNotesDraft()
                    }
                
                TextField("NRIC", text: $appState.medicalNotesDraft.patientNRIC)
                    .onChange(of: appState.medicalNotesDraft.patientNRIC) { _ in
                        appState.saveMedicalNotesDraft()
                    }
                
                TextField("Date", text: $appState.medicalNotesDraft.date)
                    .onChange(of: appState.medicalNotesDraft.date) { _ in
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
                    .onChange(of: appState.medicalNotesDraft.bp) { _ in
                        appState.saveMedicalNotesDraft()
                    }
                
                TextField("SpO2", text: $appState.medicalNotesDraft.spo2)
                    .onChange(of: appState.medicalNotesDraft.spo2) { _ in
                        appState.saveMedicalNotesDraft()
                    }
                
                TextField("Pulse Rate (PR)", text: $appState.medicalNotesDraft.pr)
                    .onChange(of: appState.medicalNotesDraft.pr) { _ in
                        appState.saveMedicalNotesDraft()
                    }
                
                TextField("Hypo Count", text: $appState.medicalNotesDraft.hypocount)
                    .onChange(of: appState.medicalNotesDraft.hypocount) { _ in
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
                        .onChange(of: appState.medicalNotesDraft.pastHistory) { _ in
                            appState.saveMedicalNotesDraft()
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("History of Presenting Complaint")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $appState.medicalNotesDraft.hpi)
                        .frame(height: 120)
                        .onChange(of: appState.medicalNotesDraft.hpi) { _ in
                            appState.saveMedicalNotesDraft()
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Physical Examination")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $appState.medicalNotesDraft.physicalExam)
                        .frame(height: 120)
                        .onChange(of: appState.medicalNotesDraft.physicalExam) { _ in
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
                        .onChange(of: appState.medicalNotesDraft.issues) { _ in
                            appState.saveMedicalNotesDraft()
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Management / Plan")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $appState.medicalNotesDraft.management)
                        .frame(height: 120)
                        .onChange(of: appState.medicalNotesDraft.management) { _ in
                            appState.saveMedicalNotesDraft()
                        }
                }
            }
            
            Section(header: Text("Clinician")) {
                TextField("Clinician Name", text: $appState.medicalNotesDraft.clinicianName)
                    .onChange(of: appState.medicalNotesDraft.clinicianName) { _ in
                        appState.saveMedicalNotesDraft()
                    }
                
                TextField("MCR Number", text: $appState.medicalNotesDraft.clinicianMCR)
                    .onChange(of: appState.medicalNotesDraft.clinicianMCR) { _ in
                        appState.saveMedicalNotesDraft()
                    }
                
                Button("Use My Profile") {
                    appState.medicalNotesDraft.clinicianName = appState.clinician.displayName
                    appState.medicalNotesDraft.clinicianMCR = appState.clinician.mcrNumber
                    appState.saveMedicalNotesDraft()
                }
            }
            
            Section {
                Button(action: generatePDF) {
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
        .sheet(isPresented: $showingPreview) {
            if let data = pdfData {
                PDFPreviewView(
                    pdfData: data,
                    filename: "\(appState.medicalNotesDraft.patientName) Notes.pdf",
                    showingExport: $showingExport
                )
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
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
    
    private func generatePDF() {
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
            guard let image = UIImage(named: template.backgroundImageName) else {
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
}
