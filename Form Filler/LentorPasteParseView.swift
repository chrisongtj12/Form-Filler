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
        // Patient info
        case "patientName":
            appState.lentorMedicalNotesDraft.patientName = value; return true
        case "nric":
            appState.lentorMedicalNotesDraft.nric = value; return true
        case "dateOfVisit":
            appState.lentorMedicalNotesDraft.dateOfVisit = value; return true
        case "nokName":
            appState.lentorMedicalNotesDraft.nokName = value; return true
        case "nokContact":
            appState.lentorMedicalNotesDraft.nokContact = value; return true
            
        // Vitals
        case "temp":
            appState.lentorMedicalNotesDraft.temp = value; return true
        case "rr":
            appState.lentorMedicalNotesDraft.rr = value; return true
        case "bp":
            appState.lentorMedicalNotesDraft.bp = value; return true
        case "spo2":
            appState.lentorMedicalNotesDraft.spo2 = value; return true
        case "pr":
            appState.lentorMedicalNotesDraft.pr = value; return true
        case "hc":
            appState.lentorMedicalNotesDraft.hc = value; return true
            
        // Weight
        case "weightMostRecent":
            appState.lentorMedicalNotesDraft.weightMostRecent = value; return true
        case "weightLeastRecent":
            appState.lentorMedicalNotesDraft.weightLeastRecent = value; return true
            
        // General condition + PE
        case "gcIssue1":
            appState.lentorMedicalNotesDraft.gcIssue1 = value; return true
        case "gcIssue2":
            appState.lentorMedicalNotesDraft.gcIssue2 = value; return true
        case "gcIssue3":
            appState.lentorMedicalNotesDraft.gcIssue3 = value; return true
        case "gcIssue4":
            appState.lentorMedicalNotesDraft.gcIssue4 = value; return true
        case "gcIssue5":
            appState.lentorMedicalNotesDraft.gcIssue5 = value; return true
        case "gcIssue6":
            appState.lentorMedicalNotesDraft.gcIssue6 = value; return true
        case "gcIssue7":
            appState.lentorMedicalNotesDraft.gcIssue7 = value; return true
        case "physicalExam":
            appState.lentorMedicalNotesDraft.physicalExam = value; return true
            
        // Page 2
        case "tcuPlan6m":
            appState.lentorMedicalNotesDraft.tcuPlan6m = value; return true
        case "docLabReportsChecked":
            appState.lentorMedicalNotesDraft.docLabReportsChecked = (value.lowercased() == "yes"); return true
        case "docLabTrendChartFill":
            appState.lentorMedicalNotesDraft.docLabTrendChartFill = (value.lowercased() == "yes"); return true
        case "docLabTrendChartPresent":
            appState.lentorMedicalNotesDraft.docLabTrendChartPresent = (value.lowercased() == "yes"); return true
        case "docMedRecRecon":
            appState.lentorMedicalNotesDraft.docMedRecRecon = (value.lowercased() == "yes"); return true
        case "docOthersText":
            appState.lentorMedicalNotesDraft.docOthersText = value; return true
            
        // Plan (page 2/3)
        case "planMedChanges":
            appState.lentorMedicalNotesDraft.planMedChanges = value; return true
        case "planLabTests":
            appState.lentorMedicalNotesDraft.planLabTests = value; return true
        case "planSpecialMonitoring":
            appState.lentorMedicalNotesDraft.planSpecialMonitoring = value; return true
        case "planFollowUpReview":
            appState.lentorMedicalNotesDraft.planFollowUpReview = value; return true
        case "planReferralsMemos":
            appState.lentorMedicalNotesDraft.planReferralsMemos = value; return true
        case "planACP":
            appState.lentorMedicalNotesDraft.planACP = value; return true
        case "planOthersUpdateNOK":
            appState.lentorMedicalNotesDraft.planOthersUpdateNOK = value; return true
            
        // Doctor
        case "doctorName":
            appState.lentorMedicalNotesDraft.doctorName = value; return true
        case "doctorMCR":
            appState.lentorMedicalNotesDraft.doctorMCR = value; return true
        case "doctorESign":
            appState.lentorMedicalNotesDraft.doctorESign = value; return true
            
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
        
        func flush() {
            if let prevKey = currentKey {
                let value = currentValue.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty {
                    result[prevKey] = value
                }
            }
            currentKey = nil
            currentValue = []
        }
        
        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            
            if let key = detectHeader(line) {
                flush()
                currentKey = key
                currentValue = []
                
                // Support "Label: value" on same line
                if let colonIndex = line.firstIndex(of: ":") {
                    let after = String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                    if !after.isEmpty {
                        // For Yes/No booleans, normalize here
                        if isBooleanField(key) {
                            currentValue = [normalizeYesNo(after)]
                        } else {
                            currentValue = [after]
                        }
                    }
                }
            } else {
                // Accumulate value lines
                if let key = currentKey {
                    if isBooleanField(key) {
                        currentValue.append(normalizeYesNo(line))
                    } else {
                        currentValue.append(line)
                    }
                }
            }
        }
        flush()
        
        return result
    }
    
    private func detectHeader(_ line: String) -> String? {
        let normalized = line.lowercased()
        
        // Patient info
        if normalized.hasPrefix("name:") || normalized.contains("name of client") {
            return "patientName"
        }
        if normalized.hasPrefix("nric:") || normalized.contains("nric of client") {
            return "nric"
        }
        if normalized.hasPrefix("date of visit:") {
            return "dateOfVisit"
        }
        if normalized.hasPrefix("nok name:") {
            return "nokName"
        }
        if normalized.hasPrefix("nok contact:") {
            return "nokContact"
        }
        
        // Vitals
        if normalized.hasPrefix("temp:") || normalized == "temp:" {
            return "temp"
        }
        if normalized.hasPrefix("rr:") || normalized == "rr:" {
            return "rr"
        }
        if normalized.hasPrefix("bp:") || normalized == "bp:" {
            return "bp"
        }
        if normalized.hasPrefix("spo2:") || normalized.contains("spO2:".lowercased()) {
            return "spo2"
        }
        if normalized.hasPrefix("pr:") || normalized == "pr:" {
            return "pr"
        }
        if normalized.hasPrefix("h/c:") || normalized.contains("h/c") {
            return "hc"
        }
        
        // Weight
        if normalized.hasPrefix("weight (most recent):") {
            return "weightMostRecent"
        }
        if normalized.hasPrefix("weight (least recent):") {
            return "weightLeastRecent"
        }
        
        // General condition
        if normalized.hasPrefix("mood/behaviour/sleep:") {
            return "gcIssue1"
        }
        if normalized.hasPrefix("oral intake/appetite:") {
            return "gcIssue2"
        }
        if normalized.hasPrefix("pain:") {
            return "gcIssue3"
        }
        if normalized.hasPrefix("bo:") {
            return "gcIssue4"
        }
        if normalized.hasPrefix("skin:") {
            return "gcIssue5"
        }
        if normalized.hasPrefix("falls (last 6/12):") {
            return "gcIssue6"
        }
        if normalized.hasPrefix("other issues:") {
            return "gcIssue7"
        }
        if normalized.hasPrefix("physical examination:") {
            return "physicalExam"
        }
        
        // Page 2
        if normalized.hasPrefix("t cus next 6 months:") || normalized.hasPrefix("tcus next 6 months:") {
            return "tcuPlan6m"
        }
        if normalized.hasPrefix("doc lab reports checked:") {
            return "docLabReportsChecked"
        }
        if normalized.hasPrefix("doc lab trend chart fill:") {
            return "docLabTrendChartFill"
        }
        if normalized.hasPrefix("doc lab trend chart present:") {
            return "docLabTrendChartPresent"
        }
        if normalized.hasPrefix("doc med rec reconciliation:") || normalized.hasPrefix("doc med rec recon:") {
            return "docMedRecRecon"
        }
        if normalized.hasPrefix("doc others:") {
            return "docOthersText"
        }
        
        // Plan (page 2/3)
        if normalized.hasPrefix("plan – medication changes:") || normalized.hasPrefix("plan - medication changes:") {
            return "planMedChanges"
        }
        if normalized.hasPrefix("plan – lab tests:") || normalized.hasPrefix("plan - lab tests:") {
            return "planLabTests"
        }
        if normalized.hasPrefix("plan – special monitoring:") || normalized.hasPrefix("plan - special monitoring:") {
            return "planSpecialMonitoring"
        }
        if normalized.hasPrefix("plan – follow-up review:") || normalized.hasPrefix("plan - follow-up review:") {
            return "planFollowUpReview"
        }
        if normalized.hasPrefix("plan – referrals / memos:") || normalized.hasPrefix("plan - referrals / memos:") {
            return "planReferralsMemos"
        }
        if normalized.hasPrefix("plan – acp:") || normalized.hasPrefix("plan - acp:") {
            return "planACP"
        }
        if normalized.hasPrefix("plan – others / update nok:") || normalized.hasPrefix("plan - others / update nok:") {
            return "planOthersUpdateNOK"
        }
        
        // Doctor
        if normalized.hasPrefix("doctor name:") {
            return "doctorName"
        }
        if normalized.hasPrefix("doctor mcr:") {
            return "doctorMCR"
        }
        if normalized.hasPrefix("doctor e-signature:") || normalized.hasPrefix("doctor e-sign:") {
            return "doctorESign"
        }
        
        return nil
    }
    
    private func isBooleanField(_ key: String) -> Bool {
        return key == "docLabReportsChecked"
        || key == "docLabTrendChartFill"
        || key == "docLabTrendChartPresent"
        || key == "docMedRecRecon"
    }
    
    private func normalizeYesNo(_ s: String) -> String {
        let v = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if v == "yes" || v == "y" || v == "✓" || v == "true" { return "Yes" }
        return "No"
    }
}

#Preview {
    LentorPasteParseView()
        .environmentObject(AppState())
}
