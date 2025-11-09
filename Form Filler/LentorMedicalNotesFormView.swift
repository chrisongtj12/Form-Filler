//
//  LentorMedicalNotesFormView.swift
//  Speedoc Clinical Notes
//
//  Form for filling out Lentor Chronic Medical Review
//

import SwiftUI

struct LentorMedicalNotesFormView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var showingPreview = false
    @State private var pdfData: Data?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingPasteParser = false
    
    var body: some View {
        Form {
            // Quick Actions
            Section {
                Button(action: {
                    showingPasteParser = true
                }) {
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
            
            // Patient Information
            Section(header: Text("Patient Information")) {
                TextField("Name of Client", text: $appState.lentorMedicalNotesDraft.patientName)
                    .onChange(of: appState.lentorMedicalNotesDraft.patientName) { _ in
                        appState.saveLentorMedicalNotesDraft()
                    }
                
                TextField("NRIC of Client", text: $appState.lentorMedicalNotesDraft.nric)
                    .onChange(of: appState.lentorMedicalNotesDraft.nric) { _ in
                        appState.saveLentorMedicalNotesDraft()
                    }
                
                TextField("Date of Visit", text: $appState.lentorMedicalNotesDraft.dateOfVisit)
                    .onChange(of: appState.lentorMedicalNotesDraft.dateOfVisit) { _ in
                        appState.saveLentorMedicalNotesDraft()
                    }
                
                Button("Set Today's Date") {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd/MM/yyyy"
                    appState.lentorMedicalNotesDraft.dateOfVisit = formatter.string(from: Date())
                    appState.saveLentorMedicalNotesDraft()
                }
            }
            
            // NOK Information
            Section(header: Text("Next of Kin")) {
                TextField("NOK Name", text: $appState.lentorMedicalNotesDraft.nokName)
                    .onChange(of: appState.lentorMedicalNotesDraft.nokName) { _ in
                        appState.saveLentorMedicalNotesDraft()
                    }
                
                TextField("NOK Contact No", text: $appState.lentorMedicalNotesDraft.nokContact)
                    .keyboardType(.phonePad)
                    .onChange(of: appState.lentorMedicalNotesDraft.nokContact) { _ in
                        appState.saveLentorMedicalNotesDraft()
                    }
            }
            
            // Vitals
            Section(header: Text("Vital Signs")) {
                HStack {
                    Text("Temp")
                        .frame(width: 80, alignment: .leading)
                    TextField("°C", text: $appState.lentorMedicalNotesDraft.temp)
                        .onChange(of: appState.lentorMedicalNotesDraft.temp) { _ in
                            appState.saveLentorMedicalNotesDraft()
                        }
                }
                
                HStack {
                    Text("RR")
                        .frame(width: 80, alignment: .leading)
                    TextField("bpm", text: $appState.lentorMedicalNotesDraft.rr)
                        .onChange(of: appState.lentorMedicalNotesDraft.rr) { _ in
                            appState.saveLentorMedicalNotesDraft()
                        }
                }
                
                HStack {
                    Text("BP")
                        .frame(width: 80, alignment: .leading)
                    TextField("mmHg", text: $appState.lentorMedicalNotesDraft.bp)
                        .onChange(of: appState.lentorMedicalNotesDraft.bp) { _ in
                            appState.saveLentorMedicalNotesDraft()
                        }
                }
                
                HStack {
                    Text("SpO2")
                        .frame(width: 80, alignment: .leading)
                    TextField("%", text: $appState.lentorMedicalNotesDraft.spo2)
                        .onChange(of: appState.lentorMedicalNotesDraft.spo2) { _ in
                            appState.saveLentorMedicalNotesDraft()
                        }
                }
                
                HStack {
                    Text("PR")
                        .frame(width: 80, alignment: .leading)
                    TextField("bpm", text: $appState.lentorMedicalNotesDraft.pr)
                        .onChange(of: appState.lentorMedicalNotesDraft.pr) { _ in
                            appState.saveLentorMedicalNotesDraft()
                        }
                }
                
                HStack {
                    Text("H/C")
                        .frame(width: 80, alignment: .leading)
                    TextField("Hypocount", text: $appState.lentorMedicalNotesDraft.hc)
                        .onChange(of: appState.lentorMedicalNotesDraft.hc) { _ in
                            appState.saveLentorMedicalNotesDraft()
                        }
                }
            }
            
            // Weight Trend
            Section(header: Text("Weight Trend")) {
                HStack {
                    Text("Most Recent")
                        .frame(width: 120, alignment: .leading)
                    TextField("kg", text: $appState.lentorMedicalNotesDraft.weightMostRecent)
                        .onChange(of: appState.lentorMedicalNotesDraft.weightMostRecent) { _ in
                            appState.saveLentorMedicalNotesDraft()
                        }
                }
                
                HStack {
                    Text("Least Recent")
                        .frame(width: 120, alignment: .leading)
                    TextField("kg", text: $appState.lentorMedicalNotesDraft.weightLeastRecent)
                        .onChange(of: appState.lentorMedicalNotesDraft.weightLeastRecent) { _ in
                            appState.saveLentorMedicalNotesDraft()
                        }
                }
            }
            
            // General Condition
            Section(header: Text("General Condition")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mood / Behaviour / Sleep")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $appState.lentorMedicalNotesDraft.gcIssue1)
                        .frame(height: 80)
                        .onChange(of: appState.lentorMedicalNotesDraft.gcIssue1) { _ in
                            appState.saveLentorMedicalNotesDraft()
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Oral Intake / Appetite / NG Aspirates")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $appState.lentorMedicalNotesDraft.gcIssue2)
                        .frame(height: 80)
                        .onChange(of: appState.lentorMedicalNotesDraft.gcIssue2) { _ in
                            appState.saveLentorMedicalNotesDraft()
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pain (if any)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $appState.lentorMedicalNotesDraft.gcIssue3)
                        .frame(height: 80)
                        .onChange(of: appState.lentorMedicalNotesDraft.gcIssue3) { _ in
                            appState.saveLentorMedicalNotesDraft()
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("BO (Bowel Opening)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $appState.lentorMedicalNotesDraft.gcIssue4)
                        .frame(height: 80)
                        .onChange(of: appState.lentorMedicalNotesDraft.gcIssue4) { _ in
                            appState.saveLentorMedicalNotesDraft()
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Skin")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $appState.lentorMedicalNotesDraft.gcIssue5)
                        .frame(height: 80)
                        .onChange(of: appState.lentorMedicalNotesDraft.gcIssue5) { _ in
                            appState.saveLentorMedicalNotesDraft()
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Falls (if any over last 6/12)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $appState.lentorMedicalNotesDraft.gcIssue6)
                        .frame(height: 80)
                        .onChange(of: appState.lentorMedicalNotesDraft.gcIssue6) { _ in
                            appState.saveLentorMedicalNotesDraft()
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Other issues (if any)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $appState.lentorMedicalNotesDraft.gcIssue7)
                        .frame(height: 80)
                        .onChange(of: appState.lentorMedicalNotesDraft.gcIssue7) { _ in
                            appState.saveLentorMedicalNotesDraft()
                        }
                }
            }
            
            // Physical Examination
            Section(header: Text("Physical Examination")) {
                TextEditor(text: $appState.lentorMedicalNotesDraft.physicalExam)
                    .frame(height: 120)
                    .onChange(of: appState.lentorMedicalNotesDraft.physicalExam) { _ in
                        appState.saveLentorMedicalNotesDraft()
                    }
            }
            
            // TCU Plan
            Section(header: Text("TCUs Planned for Next 6 Months")) {
                TextEditor(text: $appState.lentorMedicalNotesDraft.tcuPlan6m)
                    .frame(height: 100)
                    .onChange(of: appState.lentorMedicalNotesDraft.tcuPlan6m) { _ in
                        appState.saveLentorMedicalNotesDraft()
                    }
            }
            
            // Document Review
            Section(header: Text("Review of Documents")) {
                Toggle("Lab reports checked", isOn: $appState.lentorMedicalNotesDraft.docLabReportsChecked)
                    .onChange(of: appState.lentorMedicalNotesDraft.docLabReportsChecked) { _ in
                        appState.saveLentorMedicalNotesDraft()
                    }
                
                Toggle("Lab trend chart filled", isOn: $appState.lentorMedicalNotesDraft.docLabTrendChartFill)
                    .onChange(of: appState.lentorMedicalNotesDraft.docLabTrendChartFill) { _ in
                        appState.saveLentorMedicalNotesDraft()
                    }
                
                Toggle("Lab trend chart present", isOn: $appState.lentorMedicalNotesDraft.docLabTrendChartPresent)
                    .onChange(of: appState.lentorMedicalNotesDraft.docLabTrendChartPresent) { _ in
                        appState.saveLentorMedicalNotesDraft()
                    }
                
                Toggle("Med rec reconciliation done", isOn: $appState.lentorMedicalNotesDraft.docMedRecRecon)
                    .onChange(of: appState.lentorMedicalNotesDraft.docMedRecRecon) { _ in
                        appState.saveLentorMedicalNotesDraft()
                    }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Others")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Other documents reviewed", text: $appState.lentorMedicalNotesDraft.docOthersText)
                        .onChange(of: appState.lentorMedicalNotesDraft.docOthersText) { _ in
                            appState.saveLentorMedicalNotesDraft()
                        }
                }
            }
            
            // Plan (Dr to enter)
            Section(header: Text("Plan (Dr to enter)")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Medication Changes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $appState.lentorMedicalNotesDraft.planMedChanges)
                        .frame(height: 100)
                        .onChange(of: appState.lentorMedicalNotesDraft.planMedChanges) { _ in
                            appState.saveLentorMedicalNotesDraft()
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Lab Tests")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $appState.lentorMedicalNotesDraft.planLabTests)
                        .frame(height: 100)
                        .onChange(of: appState.lentorMedicalNotesDraft.planLabTests) { _ in
                            appState.saveLentorMedicalNotesDraft()
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Special Monitoring")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $appState.lentorMedicalNotesDraft.planSpecialMonitoring)
                        .frame(height: 100)
                        .onChange(of: appState.lentorMedicalNotesDraft.planSpecialMonitoring) { _ in
                            appState.saveLentorMedicalNotesDraft()
                        }
                }
            }
            
            // Page 3 Fields
            Section(header: Text("Follow-up & Additional Plans")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Follow-up Review")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $appState.lentorMedicalNotesDraft.planFollowUpReview)
                        .frame(height: 80)
                        .onChange(of: appState.lentorMedicalNotesDraft.planFollowUpReview) { _ in
                            appState.saveLentorMedicalNotesDraft()
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Referrals / Memos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $appState.lentorMedicalNotesDraft.planReferralsMemos)
                        .frame(height: 80)
                        .onChange(of: appState.lentorMedicalNotesDraft.planReferralsMemos) { _ in
                            appState.saveLentorMedicalNotesDraft()
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("ACP (Advance Care Planning)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $appState.lentorMedicalNotesDraft.planACP)
                        .frame(height: 80)
                        .onChange(of: appState.lentorMedicalNotesDraft.planACP) { _ in
                            appState.saveLentorMedicalNotesDraft()
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Others / Update NOK")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $appState.lentorMedicalNotesDraft.planOthersUpdateNOK)
                        .frame(height: 80)
                        .onChange(of: appState.lentorMedicalNotesDraft.planOthersUpdateNOK) { _ in
                            appState.saveLentorMedicalNotesDraft()
                        }
                }
            }
            
            // Doctor Details
            Section(header: Text("Doctor Details")) {
                TextField("Doctor Name", text: $appState.lentorMedicalNotesDraft.doctorName)
                    .onChange(of: appState.lentorMedicalNotesDraft.doctorName) { _ in
                        appState.saveLentorMedicalNotesDraft()
                    }
                
                TextField("Doctor MCR", text: $appState.lentorMedicalNotesDraft.doctorMCR)
                    .onChange(of: appState.lentorMedicalNotesDraft.doctorMCR) { _ in
                        appState.saveLentorMedicalNotesDraft()
                    }
                
                TextField("Doctor e-Signature", text: $appState.lentorMedicalNotesDraft.doctorESign)
                    .onChange(of: appState.lentorMedicalNotesDraft.doctorESign) { _ in
                        appState.saveLentorMedicalNotesDraft()
                    }
                
                Button("Use My Profile") {
                    appState.lentorMedicalNotesDraft.doctorName = appState.clinician.displayName
                    appState.lentorMedicalNotesDraft.doctorMCR = appState.clinician.mcrNumber
                    appState.saveLentorMedicalNotesDraft()
                }
            }
            
            // Generate PDF Button
            Section {
                Button(action: generatePDF) {
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.down.doc.fill")
                        Text("Preview & Export PDF")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Lentor Medical Review")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPreview) {
            if let data = pdfData {
                let filename = "\(appState.lentorMedicalNotesDraft.patientName.isEmpty ? "Patient" : appState.lentorMedicalNotesDraft.patientName) Lentor Notes.pdf"
                PDFPreviewView(pdfData: data, filename: filename, showingExport: .constant(false))
            }
        }
        .sheet(isPresented: $showingPasteParser) {
            LentorPasteParseView()
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    private func generatePDF() {
        // TODO: Implement PDF generation using TemplateManager
        // For now, show alert
        alertMessage = "PDF generation for Lentor forms will be implemented with template positioning. Please use the Template Editor to set up field positions first."
        showingAlert = true
    }
}

#Preview {
    NavigationView {
        LentorMedicalNotesFormView()
            .environmentObject(AppState())
    }
}
