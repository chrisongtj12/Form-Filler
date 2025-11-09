//
//  Components.swift
//  Speedoc Clinical Notes
//
//  BV Notes - Reusable UI Components
//

import SwiftUI

// MARK: - SectionCard

struct SectionCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - CopyButton

struct CopyButton: View {
    let text: String
    let onCopy: () -> Void
    
    @State private var showCheckmark = false
    
    var body: some View {
        Button(action: {
            UIPasteboard.general.string = text
            showCheckmark = true
            onCopy()
            
            // Reset checkmark after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showCheckmark = false
            }
        }) {
            HStack {
                Image(systemName: showCheckmark ? "checkmark.circle.fill" : "doc.on.doc")
                    .font(.title3)
                Text(showCheckmark ? "Copied!" : "Copy to Clipboard")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(showCheckmark ? Color.green : Color.blue)
            .cornerRadius(10)
        }
        .animation(.easeInOut(duration: 0.2), value: showCheckmark)
    }
}

// MARK: - PaymentModePicker

struct PaymentModePicker: View {
    @Binding var selectedMode: PaymentMode?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Payment Mode (Required)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack(spacing: 0) {
                ForEach(PaymentMode.allCases) { mode in
                    Button(action: {
                        selectedMode = mode
                    }) {
                        Text(mode.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedMode == mode ? .white : .blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedMode == mode ? Color.blue : Color(.systemGray6))
                    }
                }
            }
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

// MARK: - VaccineToggleRow

struct VaccineToggleRow: View {
    let vaccine: Vaccine
    let isOptional: Bool
    @Binding var selection: VaccineSelection
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                selection.selected.toggle()
                onToggle(selection.selected)
            }) {
                HStack(spacing: 12) {
                    Image(systemName: selection.selected ? "checkmark.square.fill" : "square")
                        .font(.title3)
                        .foregroundColor(selection.selected ? .blue : .gray)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(vaccine.displayName)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        if isOptional {
                            Text("Optional")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
    }
}

// MARK: - LotNumberField

struct LotNumberField: View {
    let vaccine: Vaccine
    @Binding var lotNumber: String
    let isEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Lot Number")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if lotNumber.isEmpty && isEnabled {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            TextField("Enter lot number", text: $lotNumber)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.characters)
                .disabled(!isEnabled)
                .opacity(isEnabled ? 1.0 : 0.6)
        }
    }
}

// MARK: - DosageSequenceField

struct DosageSequenceField: View {
    let vaccine: Vaccine
    @Binding var dosageSequence: String
    let isEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Dosage Sequence")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextField("e.g., Dose 1, Booster 1", text: $dosageSequence)
                .textFieldStyle(.roundedBorder)
                .disabled(!isEnabled)
                .opacity(isEnabled ? 1.0 : 0.6)
        }
    }
}

// MARK: - MilestoneListItem

struct MilestoneListItem: View {
    let milestone: Milestone
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(milestone.displayName)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text("\(milestone.applicableVaccines.count) vaccines")
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ValidationErrorBanner

struct ValidationErrorBanner: View {
    let errors: [BVValidationError]
    
    var body: some View {
        if !errors.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(errors) { error in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        
                        Text(error.message)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - ClinicalNotesPreview

struct ClinicalNotesPreview: View {
    let noteText: String
    let onCopy: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Generated Clinical Notes")
                .font(.headline)
                .foregroundColor(.primary)
            
            ScrollView {
                Text(noteText)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .frame(maxHeight: 300)
            
            CopyButton(text: noteText, onCopy: onCopy)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview Providers

#Preview("Section Card") {
    SectionCard(title: "Visit Questions") {
        Text("Sample content")
    }
    .padding()
}

#Preview("Copy Button") {
    CopyButton(text: "Sample text to copy") {
        print("Copied!")
    }
    .padding()
}

#Preview("Payment Mode Picker") {
    PaymentModePicker(selectedMode: .constant(.paynow))
        .padding()
}

#Preview("Milestone List Item - Selected") {
    MilestoneListItem(milestone: .m12, isSelected: true) {
        print("Tapped")
    }
    .padding()
}

#Preview("Milestone List Item - Unselected") {
    MilestoneListItem(milestone: .m15, isSelected: false) {
        print("Tapped")
    }
    .padding()
}

#Preview("Validation Error Banner") {
    ValidationErrorBanner(errors: [.paymentModeRequired, .multiplePCVSelected])
        .padding()
}
