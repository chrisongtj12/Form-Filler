//
//  LentorFormScreen.swift
//  Speedoc Clinical Notes
//
//  Unified Lentor form entry screen combining CMR and Service Attendance
//

import SwiftUI

struct LentorFormScreen: View {
    @EnvironmentObject var appState: AppState
    
    @ObservedObject var lentorVM: LentorFormViewModel
    
    // Validation inputs from parent
    let patientNameMissing: Bool
    let clinicianMissing: Bool
    let allNotesEmpty: Bool
    let canExport: Bool
    
    // Controls
    @Binding var showingPasteParser: Bool
    
    // Actions
    let onTapCMR: () -> Void
    let onTapServiceAttendance: () -> Void
    
    // Local formatting
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .none
        f.dateFormat = "dd/MM/yyyy"
        return f
    }()
    
    var body: some View {
        Form {
            Section(header: Text("Patient & Visit")) {
                TextField("Patient Name", text: $lentorVM.data.patientName)
                    .onChange(of: lentorVM.data.patientName) { lentorVM.save() }
                TextField("NRIC", text: $lentorVM.data.nric)
                    .textInputAutocapitalization(.characters)
                    .onChange(of: lentorVM.data.nric) { lentorVM.save() }
                DatePicker("Date of Visit", selection: $lentorVM.data.dateOfVisit, displayedComponents: .date)
                    .onChange(of: lentorVM.data.dateOfVisit) { lentorVM.save() }
                TextField("Location/Ward", text: $lentorVM.data.locationWard)
                    .onChange(of: lentorVM.data.locationWard) { lentorVM.save() }
                TextField("Service Type", text: $lentorVM.data.serviceType)
                    .onChange(of: lentorVM.data.serviceType) { lentorVM.save() }
                
                Button {
                    showingPasteParser = true
                } label: {
                    Label("Paste from Lentor Notes", systemImage: "doc.on.clipboard")
                }
            }
            
            Section(header: Text("Vitals")) {
                HStack {
                    TextField("BP", text: $lentorVM.data.bp)
                        .onChange(of: lentorVM.data.bp) { lentorVM.save() }
                    TextField("PR", text: $lentorVM.data.pr)
                        .onChange(of: lentorVM.data.pr) { lentorVM.save() }
                }
                HStack {
                    TextField("SpO₂", text: $lentorVM.data.spo2)
                        .onChange(of: lentorVM.data.spo2) { lentorVM.save() }
                    TextField("Temp", text: $lentorVM.data.temp)
                        .onChange(of: lentorVM.data.temp) { lentorVM.save() }
                    TextField("RR", text: $lentorVM.data.rr)
                        .onChange(of: lentorVM.data.rr) { lentorVM.save() }
                }
            }
            
            Section(header: Text("Clinical Content")) {
                textEditorWithCount(title: "Presenting Complaint", text: $lentorVM.data.presentingComplaint, minHeight: 80)
                textEditorWithCount(title: "History of Present Illness", text: $lentorVM.data.historyOfPresentIllness, minHeight: 100)
                textEditorWithCount(title: "Past Medical History", text: $lentorVM.data.pastMedicalHistory, minHeight: 80)
                textEditorWithCount(title: "Medication List", text: $lentorVM.data.medicationList, minHeight: 80)
                textEditorWithCount(title: "Allergies", text: $lentorVM.data.allergies, minHeight: 60)
                textEditorWithCount(title: "Physical Examination", text: $lentorVM.data.physicalExam, minHeight: 120)
            }
            .onChange(of: lentorVM.data.presentingComplaint) { lentorVM.save() }
            .onChange(of: lentorVM.data.historyOfPresentIllness) { lentorVM.save() }
            .onChange(of: lentorVM.data.pastMedicalHistory) { lentorVM.save() }
            .onChange(of: lentorVM.data.medicationList) { lentorVM.save() }
            .onChange(of: lentorVM.data.allergies) { lentorVM.save() }
            .onChange(of: lentorVM.data.physicalExam) { lentorVM.save() }
            
            Section(header: Text("Assessment & Plan")) {
                textEditorWithCount(title: "Assessment / Diagnosis", text: $lentorVM.data.assessment, minHeight: 100)
                textEditorWithCount(title: "Plan / Management", text: $lentorVM.data.plan, minHeight: 120)
            }
            .onChange(of: lentorVM.data.assessment) { lentorVM.save() }
            .onChange(of: lentorVM.data.plan) { lentorVM.save() }
            
            Section(header: Text("Service Record Details")) {
                textEditorWithCount(title: "Visit Reason", text: $lentorVM.data.visitReason, minHeight: 60)
                textEditorWithCount(title: "Interventions / Tasks Done", text: $lentorVM.data.interventions, minHeight: 80)
                TextField("Duration (mins)", text: $lentorVM.data.durationMins)
                    .keyboardType(.numberPad)
                    .onChange(of: lentorVM.data.durationMins) { lentorVM.save() }
                
                if let nextReview = lentorVM.data.nextReviewDate {
                    DatePicker("Next Review Date", selection: Binding(
                        get: { nextReview },
                        set: { lentorVM.data.nextReviewDate = $0; lentorVM.save() }
                    ), displayedComponents: .date)
                } else {
                    Button("Add Next Review Date") {
                        lentorVM.data.nextReviewDate = Date()
                        lentorVM.save()
                    }
                }
                
                if lentorVM.data.nextReviewDate != nil {
                    Button("Remove Next Review Date") {
                        lentorVM.data.nextReviewDate = nil
                        lentorVM.save()
                    }
                    .foregroundColor(.red)
                }
            }
            .onChange(of: lentorVM.data.visitReason) { lentorVM.save() }
            .onChange(of: lentorVM.data.interventions) { lentorVM.save() }
            
            Section(header: Text("Clinician")) {
                TextField("Name", text: $lentorVM.data.clinicianName)
                    .onChange(of: lentorVM.data.clinicianName) { lentorVM.save() }
                TextField("MCR", text: $lentorVM.data.clinicianMCR)
                    .textInputAutocapitalization(.characters)
                    .onChange(of: lentorVM.data.clinicianMCR) { lentorVM.save() }
                Button("Use My Profile") {
                    lentorVM.data.clinicianName = appState.clinician.displayName
                    lentorVM.data.clinicianMCR = appState.clinician.mcrNumber
                    lentorVM.save()
                }
            }
            
            if patientNameMissing || clinicianMissing {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        if patientNameMissing {
                            Label("Patient name is required to export.", systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                        }
                        if clinicianMissing {
                            Label("Clinician name and MCR are required to export.", systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            
            Section(header: Text("Export")) {
                Button {
                    onTapCMR()
                } label: {
                    HStack {
                        Image(systemName: FormKind.medicalNotes.iconName)
                        Text("Export Chronic Medical Review")
                    }
                }
                .disabled(!canExport)
                
                Button {
                    onTapServiceAttendance()
                } label: {
                    HStack {
                        Image(systemName: FormKind.homeVisitRecord.iconName)
                        Text("Export Service Attendance Record")
                    }
                }
                .disabled(!canExport)
            }
        }
        .navigationTitle("Lentor")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Helpers
    
    private func textEditorWithCount(title: String, text: Binding<String>, minHeight: CGFloat) -> some View {
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
        .padding(.vertical, 4)
    }
}

#Preview {
    LentorFormScreen(
        lentorVM: LentorFormViewModel(),
        patientNameMissing: false,
        clinicianMissing: false,
        allNotesEmpty: false,
        canExport: true,
        showingPasteParser: .constant(false),
        onTapCMR: {},
        onTapServiceAttendance: {}
    )
    .environmentObject(AppState())
}
