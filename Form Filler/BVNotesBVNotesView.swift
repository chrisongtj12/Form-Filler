//
//  BVNotesView.swift
//  Speedoc Clinical Notes
//
//  BV Notes (Baby Vaccination Notes) - Main UI
//
//  Settings have been moved to the main app Settings page.
//  This view no longer presents its own settings UI.
//

import SwiftUI

struct BVNotesView: View {
    @StateObject private var viewModel = BVNotesViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > 600 {
                // iPad: Side-by-side layout
                HStack(spacing: 0) {
                    // Left: Milestone sidebar
                    milestonesSidebar
                        .frame(width: 280)
                    
                    Divider()
                    
                    // Right: Form and output
                    formAndOutputPane
                }
            } else {
                // iPhone: Stacked layout
                VStack(spacing: 0) {
                    // Milestone grid at top (two rows / 3 columns)
                    milestoneGridCompact
                        .padding()
                        .background(Color(.systemGroupedBackground)) // adaptive
                    
                    Divider()
                    
                    // Form and output below
                    formAndOutputPane
                }
            }
        }
        .navigationTitle("BV Notes")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Milestone Sidebar (iPad) with two-column grid
    
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
            .background(Color(.secondarySystemGroupedBackground)) // adaptive section header
            
            // Milestone grid (2 columns)
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(Milestone.allCases) { milestone in
                        MilestoneListItem(
                            milestone: milestone,
                            isSelected: viewModel.currentState.milestone == milestone
                        ) {
                            viewModel.selectMilestone(milestone)
                        }
                    }
                }
                .padding(12)
            }
            .background(Color(.systemGroupedBackground)) // adaptive
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground)) // whole sidebar adaptive
    }
    
    // MARK: - Milestone Grid (iPhone) two rows
    
    private var milestoneGridCompact: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Milestone")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(Milestone.allCases) { milestone in
                    let isSelected = viewModel.currentState.milestone == milestone
                    Button {
                        viewModel.selectMilestone(milestone)
                    } label: {
                        Text(milestone.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(isSelected ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isSelected ? Color.blue : Color(.secondarySystemGroupedBackground))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
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
        .background(Color(.systemGroupedBackground)) // page background adaptive
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
                    .background(selection.selected ? Color.blue.opacity(0.05) : Color(.secondarySystemGroupedBackground))
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
                .background(Color(.secondarySystemGroupedBackground))
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
}

#Preview("BV Notes View - iPhone") {
    NavigationView {
        BVNotesView()
    }
}
