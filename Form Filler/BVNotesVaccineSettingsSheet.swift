//
//  VaccineSettingsSheet.swift
//  Speedoc Clinical Notes
//
//  BV Notes - Global vaccine settings (reusable view + optional sheet wrapper)
//

import SwiftUI

// MARK: - Reusable BV Notes Settings View (embed this in your main Settings page)

struct BVNotesSettingsView: View {
    @ObservedObject var viewModel: BVNotesViewModel
    @State private var selectedMilestoneForTemplate: Milestone = .m12
    @State private var showingRestoreAlert = false
    
    var body: some View {
        Form {
            // MARK: - Global Lot Numbers Section
            Section {
                ForEach(Vaccine.allCases) { vaccine in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(vaccine.lotNumberKey)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Lot Number", text: lotNumberBinding(for: vaccine))
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.characters)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Global Vaccine Lot Numbers")
            } footer: {
                Text("These lot numbers will be used as defaults when creating new vaccination records.")
                    .font(.caption)
            }
            
            // MARK: - Milestone Templates Section
            Section {
                Picker("Select Milestone", selection: $selectedMilestoneForTemplate) {
                    ForEach(Milestone.allCases) { milestone in
                        Text(milestone.displayName).tag(milestone)
                    }
                }
                .pickerStyle(.menu)
                
                NavigationLink(destination: MilestoneTemplateEditor(
                    viewModel: viewModel,
                    milestone: selectedMilestoneForTemplate
                )) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Edit Template")
                                .font(.body)
                            
                            Text("Configure default vaccines & follow-up plan")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Milestone Templates")
            } footer: {
                Text("Customize which vaccines are pre-selected and the default follow-up plan for each milestone.")
                    .font(.caption)
            }
            
            // MARK: - Actions
            Section {
                Button(role: .destructive) {
                    showingRestoreAlert = true
                } label: {
                    Label("Restore Defaults", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .navigationTitle("BV Notes Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Restore Defaults?", isPresented: $showingRestoreAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Restore", role: .destructive) {
                viewModel.restoreDefaultSettings()
                viewModel.saveGlobalSettings()
            }
        } message: {
            Text("This will reset all lot numbers and milestone templates to their default values. This action cannot be undone.")
        }
        .onDisappear {
            // Persist when leaving settings
            viewModel.saveGlobalSettings()
        }
    }
    
    private func lotNumberBinding(for vaccine: Vaccine) -> Binding<String> {
        Binding(
            get: {
                viewModel.globalSettings.lotNumbers[vaccine.rawValue] ?? ""
            },
            set: { newValue in
                viewModel.globalSettings.lotNumbers[vaccine.rawValue] = newValue
            }
        )
    }
}

// MARK: - Backward-compatible sheet wrapper (optional, can be removed if unused)

struct VaccineSettingsSheet: View {
    @ObservedObject var viewModel: BVNotesViewModel
    var startOnLotNumbers: Bool = true // kept for API compatibility
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            BVNotesSettingsView(viewModel: viewModel)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            viewModel.saveGlobalSettings()
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
        }
    }
}

// MARK: - Milestone Template Editor

struct MilestoneTemplateEditor: View {
    @ObservedObject var viewModel: BVNotesViewModel
    let milestone: Milestone
    
    @State private var template: MilestoneTemplate
    
    init(viewModel: BVNotesViewModel, milestone: Milestone) {
        self.viewModel = viewModel
        self.milestone = milestone
        
        // Load existing template or create default
        let existing = viewModel.globalSettings.milestoneTemplates[milestone.rawValue] ?? MilestoneTemplate()
        _template = State(initialValue: existing)
    }
    
    var body: some View {
        Form {
            Section {
                Text("Configure which vaccines should be pre-selected by default when creating a new \(milestone.displayName) record.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Section {
                ForEach(milestone.applicableVaccines) { vaccine in
                    VStack(alignment: .leading, spacing: 12) {
                        // Selection toggle
                        Toggle(isOn: defaultSelectionBinding(for: vaccine)) {
                            HStack {
                                Text(vaccine.displayName)
                                    .font(.body)
                                
                                if milestone.optionalVaccines.contains(vaccine) {
                                    Text("Optional")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange)
                                        .cornerRadius(4)
                                }
                            }
                        }
                        
                        // Default dosage sequence
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Default Dosage Sequence")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("e.g., Dose 1, Booster 1", text: defaultDosageBinding(for: vaccine))
                                .textFieldStyle(.roundedBorder)
                                .font(.subheadline)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Vaccines for \(milestone.displayName)")
            }
            
            Section {
                TextEditor(text: $template.followUpPlan)
                    .frame(minHeight: 100)
                    .font(.body)
            } header: {
                Text("Follow-up Plan")
            } footer: {
                Text("This text will be pre-filled in the Additional Notes field for new \(milestone.displayName) records.")
                    .font(.caption)
            }
            
            Section {
                Button("Save Template") {
                    viewModel.updateMilestoneTemplate(milestone, template: template)
                    viewModel.saveGlobalSettings()
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.blue)
            }
        }
        .navigationTitle("\(milestone.displayName) Template")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func defaultSelectionBinding(for vaccine: Vaccine) -> Binding<Bool> {
        Binding(
            get: {
                template.defaultSelections[vaccine.rawValue] ?? false
            },
            set: { newValue in
                template.defaultSelections[vaccine.rawValue] = newValue
            }
        )
    }
    
    private func defaultDosageBinding(for vaccine: Vaccine) -> Binding<String> {
        Binding(
            get: {
                template.defaultDosages[vaccine.rawValue] ?? "Dose 1"
            },
            set: { newValue in
                template.defaultDosages[vaccine.rawValue] = newValue
            }
        )
    }
}

// MARK: - Previews

#Preview("BV Notes Settings (embedded)") {
    NavigationView {
        BVNotesSettingsView(viewModel: BVNotesViewModel())
    }
}

#Preview("Milestone Template Editor") {
    NavigationView {
        MilestoneTemplateEditor(viewModel: BVNotesViewModel(), milestone: .m12)
    }
}
