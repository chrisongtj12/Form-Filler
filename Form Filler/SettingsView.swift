import SwiftUI

// A concrete Settings screen that wraps your templates section and related actions.
// This includes minimal scaffolding for referenced helpers so it compiles.
// If you already have these helpers elsewhere, replace the placeholders and remove these.

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    // State used by the export/import actions
    @State private var showingCopiedAlert = false
    @State private var showingImport = false
    @State private var alertMessage = ""

    var body: some View {
        Form {
            // Doctor's Info
            Section(header: Text("Clinician Information")) {
                NavigationLink(destination: ClinicianSettingsView().environmentObject(appState)) {
                    HStack {
                        Image(systemName: "person.circle")
                        Text("Doctor's Name & MCR")
                    }
                }
            }
            
            // BV Notes Settings
            Section(header: Text("Baby Vaccination Notes")) {
                NavigationLink(destination: BVNotesSettingsView(viewModel: appState.bvNotesViewModel)) {
                    HStack {
                        Image(systemName: "cross.case.fill")
                        Text("BV Notes Settings")
                    }
                }
            }
            
            // Templates management
            Section(header: Text("Templates")) {
                NavigationLink(destination: TemplateListView().environmentObject(appState)) {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text("Fill a Template")
                    }
                }

                NavigationLink(destination: TemplateEditorView().environmentObject(appState)) {
                    HStack {
                        Image(systemName: "square.and.pencil")
                        Text("Template Editor")
                    }
                }

                Button(action: {
                    appState.restoreDefaultTemplates()
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Restore Default Templates")
                    }
                }
            }
            
            // Export/Import All Settings
            Section(header: Text("Backup & Restore"), footer: Text("Export and import all settings including doctor info, BV Notes settings, and template coordinates.")) {
                Button {
                    exportAllSettings()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export All Settings")
                    }
                }

                Button {
                    showingImport = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import All Settings")
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert(alertMessage, isPresented: $showingCopiedAlert) {
            Button("OK", role: .cancel) { }
        }
        .sheet(isPresented: $showingImport) {
            ImportSettingsView { importedData in
                importAllSettings(importedData)
            }
        }
    }

    // MARK: - Helpers

    // Export all settings to JSON
    private func exportAllSettings() {
        let exportData = AllSettingsExport(
            clinician: appState.clinician,
            bvNotesSettings: appState.bvNotesViewModel.globalSettings,
            templates: appState.templates
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        guard let data = try? encoder.encode(exportData),
              let json = String(data: data, encoding: .utf8) else {
            alertMessage = "Failed to export settings"
            showingCopiedAlert = true
            return
        }
        
        ClipboardHelper.copy(json)
        alertMessage = "All settings copied to clipboard"
        showingCopiedAlert = true
    }
    
    // Import all settings from JSON
    private func importAllSettings(_ data: AllSettingsExport) {
        // Import clinician info
        appState.clinician = data.clinician
        appState.saveClinician()
        
        // Import BV Notes settings
        appState.bvNotesViewModel.globalSettings = data.bvNotesSettings
        appState.bvNotesViewModel.saveGlobalSettings()
        
        // Re-initialize current milestone with new settings
        appState.bvNotesViewModel.initializeSelections(for: appState.bvNotesViewModel.currentState.milestone)
        
        // Import templates
        appState.templates = data.templates
        appState.saveTemplates()
        
        alertMessage = "All settings imported successfully"
        showingCopiedAlert = true
    }
}

// MARK: - Data Models for Export/Import

struct AllSettingsExport: Codable {
    let version: Int = 1
    let exportDate: String = ISO8601DateFormatter().string(from: Date())
    let clinician: Clinician
    let bvNotesSettings: GlobalVaccineSettings
    let templates: [Template]
}

// MARK: - Clinician Settings View

struct ClinicianSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var displayName: String = ""
    @State private var mcrNumber: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("Doctor Information")) {
                TextField("Display Name", text: $displayName)
                    .textContentType(.name)
                
                TextField("MCR Number", text: $mcrNumber)
                    .textContentType(.username)
            }
            
            Section(header: Text("Signature")) {
                #if os(iOS)
                if let base64 = appState.clinician.defaultSignatureImagePNGBase64,
                   let data = Data(base64Encoded: base64),
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 100)
                }
                #elseif os(macOS)
                if let base64 = appState.clinician.defaultSignatureImagePNGBase64,
                   let data = Data(base64Encoded: base64),
                   let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 100)
                }
                #endif
                
                Button("Update Signature") {
                    // TODO: Add signature capture functionality
                }
            }
        }
        .navigationTitle("Clinician Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            displayName = appState.clinician.displayName
            mcrNumber = appState.clinician.mcrNumber
        }
        .onChange(of: displayName) { _, newValue in
            appState.clinician.displayName = newValue
            appState.saveClinician()
        }
        .onChange(of: mcrNumber) { _, newValue in
            appState.clinician.mcrNumber = newValue
            appState.saveClinician()
        }
    }
}

// MARK: - Import View

struct ImportSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    var onImport: (AllSettingsExport) -> Void

    @State private var text: String = ""
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Paste settings JSON below:")
                    .font(.headline)
                    .padding(.horizontal)
                
                TextEditor(text: $text)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 240)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3)))
                    .padding(.horizontal)
                
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.vertical)
            .navigationTitle("Import Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import") {
                        importSettings()
                    }
                }
            }
        }
    }

    private func importSettings() {
        guard let data = text.data(using: .utf8) else {
            errorMessage = "Invalid text encoding"
            showError = true
            return
        }
        
        let decoder = JSONDecoder()
        
        do {
            let imported = try decoder.decode(AllSettingsExport.self, from: data)
            onImport(imported)
            dismiss()
        } catch {
            errorMessage = "Failed to parse JSON: \(error.localizedDescription)"
            showError = true
        }
    }
}
