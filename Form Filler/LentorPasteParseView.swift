//
//  LentorPasteParseView.swift
//  Speedoc Clinical Notes
//
//  Paste & Parse for Lentor forms
//

import SwiftUI

struct LentorPasteParseView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var pastedText = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Paste Lentor Template")
                    .font(.headline)
                
                Text("Copy the entire Lentor form text and paste it here. The app will automatically fill in the fields.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextEditor(text: $pastedText)
                    .border(Color.gray.opacity(0.3))
                    .padding()
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Parse & Fill") {
                        parseAndFill()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(pastedText.isEmpty)
                }
                .padding(.bottom)
            }
            .navigationTitle("Paste Lentor Template")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Result", isPresented: $showingAlert) {
            Button("OK") {
                if !alertMessage.contains("Error") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func parseAndFill() {
        let parser = LentorParser()
        let parsed = parser.parse(pastedText)
        
        if parsed.isEmpty {
            alertMessage = "Could not parse any fields. Please check the format."
            showingAlert = true
            return
        }
        
        // Apply parsed values to draft
        var count = 0
        for (key, value) in parsed {
            if applyValue(value, for: key) {
                count += 1
            }
        }
        
        appState.saveLentorMedicalNotesDraft()
        
        alertMessage = "Successfully filled \(count) field\(count == 1 ? "" : "s")."
        showingAlert = true
    }
    
    private func applyValue(_ value: String, for key: String) -> Bool {
        switch key {
        case "patientName":
            appState.lentorMedicalNotesDraft.patientName = value
            return true
        case "nric":
            appState.lentorMedicalNotesDraft.nric = value
            return true
        case "dateOfVisit":
            appState.lentorMedicalNotesDraft.dateOfVisit = value
            return true
        case "nokName":
            appState.lentorMedicalNotesDraft.nokName = value
            return true
        case "nokContact":
            appState.lentorMedicalNotesDraft.nokContact = value
            return true
        case "temp":
            appState.lentorMedicalNotesDraft.temp = value
            return true
        case "rr":
            appState.lentorMedicalNotesDraft.rr = value
            return true
        case "bp":
            appState.lentorMedicalNotesDraft.bp = value
            return true
        case "spo2":
            appState.lentorMedicalNotesDraft.spo2 = value
            return true
        case "pr":
            appState.lentorMedicalNotesDraft.pr = value
            return true
        case "hc":
            appState.lentorMedicalNotesDraft.hc = value
            return true
        case "physicalExam":
            appState.lentorMedicalNotesDraft.physicalExam = value
            return true
        case "doctorName":
            appState.lentorMedicalNotesDraft.doctorName = value
            return true
        case "doctorMCR":
            appState.lentorMedicalNotesDraft.doctorMCR = value
            return true
        default:
            return false
        }
    }
}

// MARK: - Lentor Parser

struct LentorParser {
    func parse(_ text: String) -> [String: String] {
        var result: [String: String] = [:]
        let lines = text.components(separatedBy: .newlines)
        
        var currentKey: String?
        var currentValue: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Check if it's a header
            if let key = detectHeader(trimmed) {
                // Save previous key-value if exists
                if let prevKey = currentKey, !currentValue.isEmpty {
                    result[prevKey] = currentValue.joined(separator: "\n").trimmingCharacters(in: .whitespaces)
                }
                currentKey = key
                currentValue = []
            } else if !trimmed.isEmpty {
                // Accumulate value
                currentValue.append(trimmed)
            }
        }
        
        // Save last key-value
        if let prevKey = currentKey, !currentValue.isEmpty {
            result[prevKey] = currentValue.joined(separator: "\n").trimmingCharacters(in: .whitespaces)
        }
        
        return result
    }
    
    private func detectHeader(_ line: String) -> String? {
        let normalized = line.lowercased()
        
        // Patient info
        if normalized.contains("name of client") || normalized.contains("client name") {
            return "patientName"
        }
        if normalized.contains("nric of client") {
            return "nric"
        }
        if normalized.contains("date of visit") {
            return "dateOfVisit"
        }
        if normalized.contains("nok name") {
            return "nokName"
        }
        if normalized.contains("nok contact") {
            return "nokContact"
        }
        
        // Vitals
        if normalized == "temp" || normalized.contains("temperature") {
            return "temp"
        }
        if normalized == "rr" || normalized.contains("respiratory rate") {
            return "rr"
        }
        if normalized == "bp" || normalized.contains("blood pressure") {
            return "bp"
        }
        if normalized.contains("spo2") || normalized.contains("oxygen") {
            return "spo2"
        }
        if normalized == "pr" || normalized.contains("pulse rate") {
            return "pr"
        }
        if normalized.contains("h/c") || normalized.contains("hypocount") {
            return "hc"
        }
        
        // Sections
        if normalized.contains("physical examination") {
            return "physicalExam"
        }
        if normalized.contains("doctor name") {
            return "doctorName"
        }
        if normalized.contains("doctor mcr") || normalized.contains("mcr number") {
            return "doctorMCR"
        }
        
        return nil
    }
}

#Preview {
    LentorPasteParseView()
        .environmentObject(AppState())
}
