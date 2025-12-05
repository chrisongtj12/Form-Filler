//
//  ActiveGlobalFormScreen.swift
//  Speedoc Clinical Notes
//
//  Unified Active Global form entry screen used by InstitutionFormListView
//

import SwiftUI

struct ActiveGlobalFormScreen: View {
    @EnvironmentObject var appState: AppState

    @ObservedObject var agVM: ActiveGlobalFormViewModel

    // Validation inputs from parent
    let patientNameMissing: Bool
    let clinicianMissing: Bool
    let allNotesEmpty: Bool
    let canExport: Bool

    // Controls
    @Binding var showingPasteParser: Bool
    @Binding var showDestinationPicker: Bool

    // Actions
    let onTapMedicalNotes: () -> Void
    let onTapHomeVisit: () -> Void

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
                TextField("Patient Name", text: $agVM.data.patientName)
                    .onChange(of: agVM.data.patientName) { _ in agVM.save() }
                TextField("NRIC", text: $agVM.data.nric)
                    .textInputAutocapitalization(.characters)
                    .onChange(of: agVM.data.nric) { _ in agVM.save() }
                DatePicker("Date of Visit", selection: $agVM.data.dateOfVisit, displayedComponents: .date)
                    .onChange(of: agVM.data.dateOfVisit) { _ in agVM.save() }
                TextField("Client / NOK", text: $agVM.data.clientOrNOK)
                    .onChange(of: agVM.data.clientOrNOK) { _ in agVM.save() }

                Button {
                    showingPasteParser = true
                } label: {
                    Label("Paste from AG Medical Notes", systemImage: "doc.on.clipboard")
                }
            }

            Section(header: Text("Vitals")) {
                HStack {
                    TextField("BP", text: $agVM.data.bp)
                        .onChange(of: agVM.data.bp) { _ in agVM.save() }
                    TextField("SpO₂", text: $agVM.data.spo2)
                        .onChange(of: agVM.data.spo2) { _ in agVM.save() }
                }
                HStack {
                    TextField("PR", text: $agVM.data.pr)
                        .onChange(of: agVM.data.pr) { _ in agVM.save() }
                    TextField("Hypocount", text: $agVM.data.hypocount)
                        .onChange(of: agVM.data.hypocount) { _ in agVM.save() }
                }
            }

            Section(header: Text("Notes")) {
                textEditorWithCount(title: "Past Medical History", text: $agVM.data.pastMedicalHistory, minHeight: 80)
                textEditorWithCount(title: "Presenting Complaint / HPI", text: $agVM.data.presentingComplaint, minHeight: 120)
                textEditorWithCount(title: "Physical Examination", text: $agVM.data.physicalExam, minHeight: 120)
                textEditorWithCount(title: "Diagnosis / Issues", text: $agVM.data.diagnosisIssues, minHeight: 100)
                textEditorWithCount(title: "Management Plan", text: $agVM.data.managementPlan, minHeight: 120)
            }
            .onChange(of: agVM.data.pastMedicalHistory) { _ in agVM.save() }
            .onChange(of: agVM.data.presentingComplaint) { _ in agVM.save() }
            .onChange(of: agVM.data.physicalExam) { _ in agVM.save() }
            .onChange(of: agVM.data.diagnosisIssues) { _ in agVM.save() }
            .onChange(of: agVM.data.managementPlan) { _ in agVM.save() }

            Section(header: Text("Clinician")) {
                TextField("Name", text: $agVM.data.clinicianName)
                    .onChange(of: agVM.data.clinicianName) { _ in agVM.save() }
                TextField("MCR", text: $agVM.data.clinicianMCR)
                    .textInputAutocapitalization(.characters)
                    .onChange(of: agVM.data.clinicianMCR) { _ in agVM.save() }
                Button("Use My Profile") {
                    agVM.data.clinicianName = appState.clinician.displayName
                    agVM.data.clinicianMCR = appState.clinician.mcrNumber
                    agVM.save()
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
                    onTapMedicalNotes()
                } label: {
                    HStack {
                        Image(systemName: FormKind.medicalNotes.iconName)
                        Text("Export Medical Notes")
                    }
                }
                .disabled(!canExport)

                Button {
                    onTapHomeVisit()
                } label: {
                    HStack {
                        Image(systemName: FormKind.homeVisitRecord.iconName)
                        Text("Export Home Visit Record")
                    }
                }
                .disabled(!canExport)
            }
        }
        .navigationTitle("Active Global")
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
                .onChange(of: text.wrappedValue) { _ in
                    agVM.save()
                }
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
    ActiveGlobalFormScreen(
        agVM: ActiveGlobalFormViewModel(),
        patientNameMissing: false,
        clinicianMissing: false,
        allNotesEmpty: false,
        canExport: true,
        showingPasteParser: .constant(false),
        showDestinationPicker: .constant(false),
        onTapMedicalNotes: {},
        onTapHomeVisit: {}
    )
    .environmentObject(AppState())
}
