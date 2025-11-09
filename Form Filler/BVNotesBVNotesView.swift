//
//  BVNotesView.swift
//  Speedoc Clinical Notes
//
//  BV Notes (Baby Vaccination Notes) - Main UI
//
//  WORKFLOW:
//  1. Left sidebar: Select milestone (2m, 4m, 6m, 12m, 15m, 18m)
//  2. Right pane: Fill out visit details, select vaccines, enter lot numbers
//  3. View generated clinical note in readable table format
//  4. Copy to clipboard for pasting into Avixo
//
//  FEATURES:
//  - PCV mutual exclusion (only one of PCV13/15/20 can be selected)
//  - Optional vaccines require payment mode (except Influenza)
//  - Global vaccine settings (lot numbers + milestone templates)
//  - Auto-save state per milestone
//  - Side effects note quick-insert
//

import SwiftUI

struct BVNotesView: View {
    @StateObject private var viewModel = BVNotesViewModel()
    @State private var showingSettings = false
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > 600 {
                // iPad: Side-by-side layout
                HStack(spacing: 0) {
                    // Left: Milestone sidebar
                    milestonesSidebar
                        .frame(width: 240)
                    
                    Divider()
                    
                    // Right: Form and output
                    formAndOutputPane
                }
            } else {
                // iPhone: Stacked layout
                VStack(spacing: 0) {
                    // Milestone picker at top
                    milestonePicker
                        .padding()
                        .background(Color(.systemGray6))
                    
                    Divider()
                    
                    // Form and output below
                    formAndOutputPane
                }
            }
        }
        .navigationTitle("BV Notes")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSettings) {
            VaccineSettingsSheet(viewModel: viewModel)
        }
    }
    
    // MARK: - Milestone Sidebar (iPad)
    
    private var milestonesSidebar: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Milestones")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Select visit age")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            
            // Milestone list
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Milestone.allCases) { milestone in
                        MilestoneListItem(
                            milestone: milestone,
                            isSelected: viewModel.currentState.milestone == milestone
                        ) {
                            viewModel.selectMilestone(milestone)
                        }
                        .padding(.horizontal, 12)
                    }
                }
                .padding(.vertical, 12)
            }
            
            Spacer()
            
            // Settings button at bottom
            Button(action: {
                showingSettings = true
            }) {
                HStack {
                    Image(systemName: "gear")
                    Text("Vaccine Settings")
                        .font(.subheadline)
                }
                .foregroundColor(.blue)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
            }
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Milestone Picker (iPhone)
    
    private var milestonePicker: some View {
        VStack(spacing: 12) {
            Text("Select Milestone")
                .font(.headline)
            
            Picker("Milestone", selection: Binding(
                get: { viewModel.currentState.milestone },
                set: { viewModel.selectMilestone($0) }
            )) {
                ForEach(Milestone.allCases) { milestone in
                    Text(milestone.displayName).tag(milestone)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    // MARK: - Form and Output Pane
    
    private var formAndOutputPane: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Validation errors
                if !viewModel.validationErrors.isEmpty {
                    ValidationErrorBanner(errors: viewModel.validationErrors)
                        .padding(.horizontal)
                }
                
                // Visit Questions Section
                visitQuestionsSection
                
                // Vaccines Section
                vaccinesSection
                
                // Payment Mode (conditional)
                if viewModel.requiresPaymentMode {
                    paymentModeSection
                }
                
                // Additional Notes Section
                additionalNotesSection
                
                // Generated Clinical Notes
                generatedNotesSection
            }
            .padding()
        }
        .background(Color(.systemGray6))
    }
    
    // MARK: - Visit Questions Section
    
    private var visitQuestionsSection: some View {
        SectionCard(title: "Visit Questions") {
            VStack(alignment: .leading, spacing: 16) {
                // Date of Visit
                DatePicker(
                    "Date of Visit",
                    selection: Binding(
                        get: { viewModel.currentState.dateOfVisit },
                        set: { newDate in
                            viewModel.currentState.dateOfVisit = newDate
                            viewModel.saveCurrentState()
                        }
                    ),
                    displayedComponents: .date
                )
                
                Divider()
                
                // CDS
                VStack(alignment: .leading, spacing: 8) {
                    Text("CDS done during this visit?")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("CDS", selection: Binding(
                        get: { viewModel.currentState.cds },
                        set: { viewModel.updateCDS($0) }
                    )) {
                        ForEach(CDS.allCases) { cds in
                            Text(cds.rawValue).tag(cds)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }
    
    // MARK: - Vaccines Section
    
    private var vaccinesSection: some View {
        SectionCard(title: "Vaccines for \(viewModel.currentState.milestone.displayName)") {
            VStack(spacing: 16) {
                ForEach(viewModel.currentState.selections.indices, id: \.self) { index in
                    let selection = viewModel.currentState.selections[index]
                    let isOptional = viewModel.currentState.milestone.optionalVaccines.contains(selection.vaccine)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Vaccine toggle
                        VaccineToggleRow(
                            vaccine: selection.vaccine,
                            isOptional: isOptional,
                            selection: $viewModel.currentState.selections[index],
                            onToggle: { isSelected in
                                viewModel.toggleVaccineSelection(vaccine: selection.vaccine, isSelected: isSelected)
                            }
                        )
                        
                        if selection.selected {
                            // Lot Number
                            LotNumberField(
                                vaccine: selection.vaccine,
                                lotNumber: Binding(
                                    get: { viewModel.currentState.selections[index].lotNumber },
                                    set: { viewModel.updateLotNumber(for: selection.vaccine, lotNumber: $0) }
                                ),
                                isEnabled: true
                            )
                            
                            // Dosage Sequence
                            DosageSequenceField(
                                vaccine: selection.vaccine,
                                dosageSequence: Binding(
                                    get: { viewModel.currentState.selections[index].dosageSequence },
                                    set: { viewModel.updateDosageSequence(for: selection.vaccine, sequence: $0) }
                                ),
                                isEnabled: true
                            )
                        }
                    }
                    .padding()
                    .background(selection.selected ? Color.blue.opacity(0.05) : Color(.systemGray6))
                    .cornerRadius(8)
                    
                    if index < viewModel.currentState.selections.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }
    
    // MARK: - Payment Mode Section
    
    private var paymentModeSection: some View {
        SectionCard(title: "Payment Information") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Optional vaccines selected (except Influenza) require payment mode.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                PaymentModePicker(selectedMode: Binding(
                    get: { viewModel.currentState.paymentMode },
                    set: { viewModel.updatePaymentMode($0) }
                ))
            }
        }
    }
    
    // MARK: - Additional Notes Section
    
    private var additionalNotesSection: some View {
        SectionCard(title: "Additional Notes") {
            VStack(alignment: .leading, spacing: 12) {
                TextEditor(text: Binding(
                    get: { viewModel.currentState.additionalNotes },
                    set: { viewModel.updateAdditionalNotes($0) }
                ))
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                HStack {
                    Button(action: {
                        viewModel.appendSideEffectsNote()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Side Effects Note")
                                .font(.subheadline)
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.resetToDefaults()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset")
                                .font(.subheadline)
                        }
                        .foregroundColor(.orange)
                    }
                }
            }
        }
    }
    
    // MARK: - Generated Notes Section
    
    private var generatedNotesSection: some View {
        ClinicalNotesPreview(
            noteText: viewModel.generateClinicalNote(),
            onCopy: {
                // Optional: Add haptic feedback
                #if os(iOS)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                #endif
            }
        )
    }
}

// MARK: - Preview

#Preview("BV Notes View - iPad") {
    NavigationView {
        BVNotesView()
    }
    .previewDevice("iPad Pro (12.9-inch) (6th generation)")
}

#Preview("BV Notes View - iPhone") {
    NavigationView {
        BVNotesView()
    }
    .previewDevice("iPhone 15 Pro")
}

#Preview("BV Notes View - 12 Month") {
    let viewModel = BVNotesViewModel()
    viewModel.selectMilestone(.m12)
    
    return NavigationView {
        BVNotesView()
    }
}

#Preview("BV Notes View - 15 Month with Optional") {
    let viewModel = BVNotesViewModel()
    viewModel.selectMilestone(.m15)
    
    return NavigationView {
        BVNotesView()
    }
}
