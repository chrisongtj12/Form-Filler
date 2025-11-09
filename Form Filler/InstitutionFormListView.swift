//
//  InstitutionFormListView.swift
//  Speedoc Clinical Notes
//
//  List of forms for a specific institution
//

import SwiftUI

struct InstitutionFormListView: View {
    @EnvironmentObject var appState: AppState
    let institution: Institution
    
    @State private var showingPasteParser = false
    @State private var showingLentorPasteParser = false
    
    var body: some View {
        List {
            // Quick Actions Section
            if institution == .activeGlobal {
                Section {
                    Button(action: {
                        showingPasteParser = true
                    }) {
                        HStack {
                            Image(systemName: "doc.on.clipboard.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("Paste AVIXO Template")
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
            } else if institution == .lentor {
                Section {
                    Button(action: {
                        showingLentorPasteParser = true
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
            }
            
            // Forms Section
            Section(header: Text("Forms")) {
                ForEach(FormRegistry.shared.forms(for: institution)) { form in
                    NavigationLink(destination: destinationView(for: form)) {
                        HStack {
                            Image(systemName: form.kind.iconName)
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(form.title)
                                    .font(.headline)
                                Text("\(form.pageCount) page\(form.pageCount > 1 ? "s" : "")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(institution.displayName)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingPasteParser) {
            PasteParseView()
        }
        .sheet(isPresented: $showingLentorPasteParser) {
            LentorPasteParseView()
                .environmentObject(appState)
        }
    }
    
    @ViewBuilder
    private func destinationView(for form: FormDescriptor) -> some View {
        switch (form.institution, form.kind) {
        case (.activeGlobal, .medicalNotes):
            MedicalNotesFormView()
        case (.activeGlobal, .homeVisitRecord):
            HVRecordFormView()
        case (.lentor, .medicalNotes):
            LentorMedicalNotesFormView()
        case (.lentor, .homeVisitRecord):
            LentorHVRecordFormView()
        }
    }
}

#Preview {
    NavigationView {
        InstitutionFormListView(institution: .activeGlobal)
            .environmentObject(AppState())
    }
}

