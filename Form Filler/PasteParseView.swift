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
    @State private var showingSamplePicker = false
    
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
                    
                    #if DEBUG
                    Button(action: {
                        showingSamplePicker = true
                    }) {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                            Text("Load Sample")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(10)
                    }
                    #endif
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
            .confirmationDialog("Load Sample Template", isPresented: $showingSamplePicker, titleVisibility: .visible) {
                Button("Complete Example") {
                    pastedText = SampleAvixoTemplates.complete
                }
                Button("Minimal Example") {
                    pastedText = SampleAvixoTemplates.minimal
                }
                Button("Next Line Values") {
                    pastedText = SampleAvixoTemplates.nextLineValues
                }
                Button("Variable Formatting") {
                    pastedText = SampleAvixoTemplates.variableFormatting
                }
                Button("Complex Multi-line") {
                    pastedText = SampleAvixoTemplates.complexMultiLine
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
    
    private func parseAndFill() {
        let trimmed = pastedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Parse the text
        let note = parseAvixoDump(trimmed)
        parsedNote = note
        
        // If you want immediate application without preview, uncomment the next line and remove showingPreview
        applyParsedData(note)
        // showingPreview = true
    }
    
    private func applyParsedData(_ note: ClinicalNote) {
        // Update the medical notes draft with parsed data
        appState.medicalNotesDraft = note.toMedicalNotesData(existingData: appState.medicalNotesDraft)
        appState.saveMedicalNotesDraft()
        
        // Show summary
        summaryMessage = note.filledFieldsSummary
        showingSummary = true
        
        // Close preview sheet if open
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
