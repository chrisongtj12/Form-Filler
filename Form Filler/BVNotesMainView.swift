//
//  BVNotesMainView.swift
//  Speedoc Clinical Notes
//
//  Baby Vaccination notes - Main entry view
//

import SwiftUI

struct BVNotesMainView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = BVNotesViewModel()
    
    var body: some View {
        Form {
            milestoneSection
            patientInfoSection
            vaccineSelectionSection
            clinicalDetailsSection
            paymentSection
            clinicianSection
            validationSection
            actionsSection
        }
        .navigationTitle("Baby Vaccination")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.validate()
        }
        .onChange(of: viewModel.currentState.patientName) { _ in viewModel.validate() }
        .onChange(of: viewModel.currentState.patientNRIC) { _ in viewModel.validate() }
        .onChange(of: viewModel.currentState.selections) { _ in viewModel.validate() }
    }
    
    // MARK: - Sections broken out to help the type-checker
    
    private var milestoneSection: some View {
        Section(header: Text("Milestone Selection")) {
            Picker("Age Milestone", selection: $viewModel.currentState.milestone) {
                ForEach(Milestone.allCases, id: \.self) { milestone in
                    Text(milestone.displayName).tag(milestone)
                }
            }
            .onChange(of: viewModel.currentState.milestone) { newMilestone in
                viewModel.selectMilestone(newMilestone)
            }
        }
    }
    
    private var patientInfoSection: some View {
        Section(header: Text("Patient Information")) {
            TextField("Patient Name", text: $viewModel.currentState.patientName)
            TextField("NRIC / ID", text: $viewModel.currentState.patientNRIC)
                .textInputAutocapitalization(.characters)
            DatePicker("Date of Visit", selection: $viewModel.currentState.dateOfVisit, displayedComponents: .date)
        }
    }
    
    private var vaccineSelectionSection: some View {
        Section(header: Text("Vaccine Selection")) {
            ForEach($viewModel.currentState.selections, id: \.id) { $selection in
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $selection.selected) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selection.vaccine.fullName)
                                .font(.body)
                            Text(selection.vaccine.shortName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if selection.selected {
                        HStack {
                            TextField("Lot Number", text: $selection.lotNumber)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: selection.lotNumber) { newValue in
                                    viewModel.updateLotNumberInSettings(for: selection.vaccine, lotNumber: newValue)
                                }
                            
                            TextField("Dosage", text: $selection.dosageSequence)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private var clinicalDetailsSection: some View {
        Section(header: Text("Clinical Details")) {
            Picker("Child Development Screening", selection: $viewModel.currentState.cds) {
                Text("Yes").tag(CDS.yes)
                Text("No").tag(CDS.no)
                Text("Other").tag(CDS.other)
            }
            .pickerStyle(.segmented)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.currentState.additionalNotes)
                    .frame(minHeight: 100)
                if viewModel.currentState.additionalNotes.isEmpty {
                    Text("Additional notes, follow-up plan, or observations...")
                        .foregroundColor(.secondary)
                        .opacity(0.5)
                        .padding(8)
                        .allowsHitTesting(false)
                }
            }
        }
    }
    
    private var paymentSection: some View {
        Section(header: Text("Payment")) {
            Picker("Payment Mode", selection: $viewModel.currentState.paymentMode) {
                Text("Not Selected").tag(nil as PaymentMode?)
                ForEach(PaymentMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode as PaymentMode?)
                }
            }
        }
    }
    
    private var clinicianSection: some View {
        Section(header: Text("Clinician")) {
            TextField("Name", text: Binding(
                get: { appState.clinician.displayName },
                set: { _ in }
            ))
            .disabled(true)
            
            TextField("MCR", text: Binding(
                get: { appState.clinician.mcrNumber },
                set: { _ in }
            ))
            .disabled(true)
        }
    }
    
    private var validationSection: some View {
        Group {
            if !viewModel.validationErrors.isEmpty {
                Section(header: Text("Validation Errors")) {
                    ForEach(viewModel.validationErrors, id: \.id) { error in
                        Label(error.message, systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }
    
    private var actionsSection: some View {
        Section {
            Button {
                exportPDF()
            } label: {
                HStack {
                    Image(systemName: "doc.fill")
                    Text("Export PDF")
                    Spacer()
                }
            }
            .disabled(!viewModel.validationErrors.isEmpty)
            
            Button("Reset Form") {
                viewModel.resetToDefaults()
            }
            .foregroundColor(.red)
        }
    }
    
    private func exportPDF() {
        // Save current state
        viewModel.saveCurrentState()
        
        // TODO: Implement PDF export based on selected milestone and vaccines
        // This would generate a vaccination record PDF similar to medical notes export
        print("Export PDF for milestone: \(viewModel.currentState.milestone.displayName)")
        print("Selected vaccines: \(viewModel.currentState.selections.filter(\.selected).map(\.vaccine.shortName))")
    }
}

#Preview {
    NavigationView {
        BVNotesMainView()
            .environmentObject(AppState())
    }
}

