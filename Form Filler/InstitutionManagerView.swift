//
//  InstitutionManagerView.swift
//  Speedoc Clinical Notes
//
//  Manage institutions - add, edit, delete
//

import SwiftUI

struct InstitutionManagerView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddSheet = false
    @State private var editingInstitution: Institution?
    @State private var showingDeleteAlert = false
    @State private var institutionToDelete: Institution?
    
    var body: some View {
        List {
            ForEach(appState.institutions) { institution in
                HStack {
                    Image(systemName: institution.iconName)
                        .foregroundColor(.accentColor)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(institution.displayName)
                            .font(.headline)
                        Text(institution.subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        editingInstitution = institution
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.borderless)
                    
                    Button(role: .destructive, action: {
                        institutionToDelete = institution
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .navigationTitle("Manage Institutions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            InstitutionEditorSheet(
                institution: nil,
                isPresented: $showingAddSheet,
                onSave: { newInstitution in
                    appState.institutions.append(newInstitution)
                    appState.saveInstitutions()
                }
            )
        }
        .sheet(item: $editingInstitution) { institution in
            InstitutionEditorSheet(
                institution: institution,
                isPresented: Binding(
                    get: { editingInstitution != nil },
                    set: { if !$0 { editingInstitution = nil } }
                ),
                onSave: { updatedInstitution in
                    if let index = appState.institutions.firstIndex(where: { $0.id == updatedInstitution.id }) {
                        appState.institutions[index] = updatedInstitution
                        appState.saveInstitutions()
                    }
                }
            )
        }
        .alert("Delete Institution?", isPresented: $showingDeleteAlert, presenting: institutionToDelete) { institution in
            Button("Delete", role: .destructive) {
                if let index = appState.institutions.firstIndex(where: { $0.id == institution.id }) {
                    appState.institutions.remove(at: index)
                    appState.saveInstitutions()
                }
                institutionToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                institutionToDelete = nil
            }
        } message: { institution in
            Text("Are you sure you want to delete \"\(institution.displayName)\"?")
        }
    }
}

// MARK: - Institution Editor Sheet

struct InstitutionEditorSheet: View {
    let institution: Institution?
    @Binding var isPresented: Bool
    let onSave: (Institution) -> Void
    
    @State private var displayName: String
    @State private var subtitle: String
    @State private var selectedIcon: String
    
    // Common SF Symbols for buildings/organizations
    private let iconOptions = [
        "building.2.fill",
        "building.fill",
        "building.columns.fill",
        "cross.fill",
        "cross.case.fill",
        "house.fill",
        "house.and.flag.fill",
        "staroflife.fill",
        "heart.fill",
        "medical.thermometer.fill",
        "bandage.fill"
    ]
    
    init(institution: Institution?, isPresented: Binding<Bool>, onSave: @escaping (Institution) -> Void) {
        self.institution = institution
        self._isPresented = isPresented
        self.onSave = onSave
        
        // Initialize state with existing values or defaults
        _displayName = State(initialValue: institution?.displayName ?? "")
        _subtitle = State(initialValue: institution?.subtitle ?? "")
        _selectedIcon = State(initialValue: institution?.iconName ?? "building.2.fill")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Institution Details")) {
                    TextField("Name", text: $displayName)
                    TextField("Subtitle", text: $subtitle)
                }
                
                Section(header: Text("Icon")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 16) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button(action: {
                                selectedIcon = icon
                            }) {
                                VStack {
                                    Image(systemName: icon)
                                        .font(.system(size: 28))
                                        .foregroundColor(selectedIcon == icon ? .white : .accentColor)
                                        .frame(width: 60, height: 60)
                                        .background(selectedIcon == icon ? Color.accentColor : Color.clear)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.accentColor, lineWidth: selectedIcon == icon ? 2 : 1)
                                        )
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Preview")) {
                    HStack {
                        Image(systemName: selectedIcon)
                            .foregroundColor(.accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(displayName.isEmpty ? "Institution Name" : displayName)
                                .font(.headline)
                            Text(subtitle.isEmpty ? "Subtitle" : subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(institution == nil ? "Add Institution" : "Edit Institution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let savedInstitution = Institution(
                            id: institution?.id ?? UUID(),
                            displayName: displayName,
                            subtitle: subtitle,
                            iconName: selectedIcon
                        )
                        onSave(savedInstitution)
                        isPresented = false
                    }
                    .disabled(displayName.isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Institution Manager") {
    NavigationView {
        InstitutionManagerView()
            .environmentObject(AppState())
    }
}

#Preview("Add Institution") {
    InstitutionEditorSheet(
        institution: nil,
        isPresented: .constant(true),
        onSave: { _ in }
    )
}

#Preview("Edit Institution") {
    InstitutionEditorSheet(
        institution: Institution.activeGlobal,
        isPresented: .constant(true),
        onSave: { _ in }
    )
}
