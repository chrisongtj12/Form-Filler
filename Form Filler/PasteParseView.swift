//
//  PasteParseView.swift
//  Speedoc Clinical Notes
//
//  UI for pasting and parsing AVIXO template text
//

import SwiftUI

struct PasteParseView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var pastedText: String = ""
    @State private var showingPreview = false
    @State private var parsedNote: ClinicalNote?
    @State private var showingSummary = false
    @State private var summaryMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Paste AVIXO Template")
                            .font(.headline)
                    }
                    
                    Text("Copy the AVIXO Home Medical Notes text and paste it below. The app will automatically parse and fill the form fields.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                
                // Text editor for pasted content
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pasted Text")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    TextEditor(text: $pastedText)
                        .font(.system(.body, design: .monospaced))
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .border(Color.gray.opacity(0.3), width: 1)
                        .padding(.horizontal)
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: parseAndFill) {
                        HStack {
                            Image(systemName: "doc.text.fill.badge.plus")
                            Text("Parse & Fill")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    Button(action: pasteFromClipboard) {
                        HStack {
                            Image(systemName: "doc.on.clipboard")
                            Text("Paste from Clipboard")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                    }
                    
                    Button(action: clearText) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                    }
                    .disabled(pastedText.isEmpty)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Paste & Parse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPreview) {
                if let note = parsedNote {
                    ParsePreviewView(
                        parsedNote: note,
                        onApply: {
                            applyParsedData(note)
                        },
                        onCancel: {
                            showingPreview = false
                        }
                    )
                    .environmentObject(appState)
                }
            }
            .alert("Parse Summary", isPresented: $showingSummary) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(summaryMessage)
            }
        }
    }
    
    private func parseAndFill() {
        let trimmed = pastedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Parse the text
        let note = parseAvixoDump(trimmed)
        parsedNote = note
        
        // Show preview sheet
        showingPreview = true
    }
    
    private func applyParsedData(_ note: ClinicalNote) {
        // Update the medical notes draft with parsed data
        appState.medicalNotesDraft = note.toMedicalNotesData(existingData: appState.medicalNotesDraft)
        appState.saveMedicalNotesDraft()
        
        // Show summary
        summaryMessage = note.filledFieldsSummary
        showingSummary = true
        
        // Close preview sheet
        showingPreview = false
        
        // Dismiss after a short delay to let user see the summary
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
    
    private func pasteFromClipboard() {
        if let clipboardString = UIPasteboard.general.string {
            pastedText = clipboardString
        }
    }
    
    private func clearText() {
        pastedText = ""
    }
}

// MARK: - Parse Preview View

struct ParsePreviewView: View {
    @EnvironmentObject var appState: AppState
    let parsedNote: ClinicalNote
    let onApply: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Parsed Data Preview")) {
                    Text("Review the parsed information below. Empty fields will not overwrite existing data.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !parsedNote.patientName.isEmpty {
                    Section(header: Text("Patient Information")) {
                        LabeledContent("Name", value: parsedNote.patientName)
                        if !parsedNote.nric.isEmpty {
                            LabeledContent("NRIC", value: parsedNote.nric)
                        }
                        if !parsedNote.dateOfVisit.isEmpty {
                            LabeledContent("Date", value: parsedNote.dateOfVisit)
                        }
                        if !parsedNote.clientOrNOK.isEmpty {
                            LabeledContent("Client/NOK", value: parsedNote.clientOrNOK)
                        }
                    }
                }
                
                Section(header: Text("Vital Signs")) {
                    if !parsedNote.bp.isEmpty {
                        LabeledContent("BP", value: parsedNote.bp)
                    }
                    if !parsedNote.spo2.isEmpty {
                        LabeledContent("SpO2", value: parsedNote.spo2)
                    }
                    if !parsedNote.pr.isEmpty {
                        LabeledContent("PR", value: parsedNote.pr)
                    }
                    if !parsedNote.hypocount.isEmpty {
                        LabeledContent("Hypocount", value: parsedNote.hypocount)
                    }
                    
                    if parsedNote.bp.isEmpty && parsedNote.spo2.isEmpty && 
                       parsedNote.pr.isEmpty && parsedNote.hypocount.isEmpty {
                        Text("No vital signs found")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                
                if !parsedNote.pmh.isEmpty {
                    Section(header: Text("Past Medical History")) {
                        Text(parsedNote.pmh)
                            .font(.body)
                    }
                }
                
                if !parsedNote.presentingComplaint.isEmpty {
                    Section(header: Text("Presenting Complaint")) {
                        Text(parsedNote.presentingComplaint)
                            .font(.body)
                    }
                }
                
                if !parsedNote.physicalExam.isEmpty {
                    Section(header: Text("Physical Examination")) {
                        Text(parsedNote.physicalExam)
                            .font(.body)
                    }
                }
                
                if !parsedNote.issues.isEmpty {
                    Section(header: Text("Issues")) {
                        Text(parsedNote.issues)
                            .font(.body)
                    }
                }
                
                if !parsedNote.plan.isEmpty {
                    Section(header: Text("Plan")) {
                        Text(parsedNote.plan)
                            .font(.body)
                    }
                }
                
                Section(header: Text("Summary")) {
                    Text(parsedNote.filledFieldsSummary)
                        .font(.caption)
                }
                
                Section {
                    Button(action: onApply) {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                            Text("Apply to Form")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .foregroundColor(.green)
                }
            }
            .navigationTitle("Review Parsed Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }
}

#Preview("Paste Parse View - Empty") {
    PasteParseView()
        .environmentObject(AppState())
}

#Preview("Paste Parse View - With Sample") {
    let view = PasteParseView()
    view.pastedText = """
    Name: John Tan
    NRIC: S1234567A
    Date of Visit: 2025-11-08
    
    BP: 120/80
    SpO2: 98%
    PR: 72
    
    Past Medical History:
    Hypertension, Type 2 Diabetes Mellitus
    
    Presenting Complaint:
    Patient presents with fever and cough for 3 days.
    
    Physical Examination:
    Alert and conscious. Lungs clear bilaterally.
    
    Issues:
    1. Upper respiratory tract infection
    
    Plan:
    1. Paracetamol 500mg TDS
    2. Review in 3 days if not improving
    """
    return view
        .environmentObject(AppState())
}

#Preview("Parse Preview View") {
    ParsePreviewView(
        parsedNote: ClinicalNote(
            patientName: "John Tan",
            nric: "S1234567A",
            dateOfVisit: "2025-11-08",
            clientOrNOK: "",
            bp: "120/80",
            spo2: "98%",
            pr: "72",
            hypocount: "",
            pmh: "Hypertension, Type 2 Diabetes Mellitus",
            presentingComplaint: "Patient presents with fever and cough for 3 days.",
            physicalExam: "Alert and conscious. Lungs clear bilaterally.",
            issues: "1. Upper respiratory tract infection",
            plan: "1. Paracetamol 500mg TDS\n2. Review in 3 days if not improving"
        ),
        onApply: {},
        onCancel: {}
    )
    .environmentObject(AppState())
}
