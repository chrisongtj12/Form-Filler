//
//  SettingsView.swift
//  Speedoc Clinical Notes
//
//  Settings screen for profiles and template editing
//

import SwiftUI
import Combine

// Adapter to bridge AppState to the generic TemplatePersisting interface
final class AppStateTemplateAdapter: TemplatePersisting {
    @Published var templates: [Template]
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
        self.templates = appState.templates
    }

    func save() {
        appState.saveTemplates(templates)
        // Keep AppState in sync with any mutations
        appState.templates = templates
    }
}

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var adapter: AppStateTemplateAdapter? = nil
    
    // Local UI state for export alert and import sheet
    @State private var showingCopiedAlert = false
    @State private var showingImport = false
    
    // BV Notes settings view model (persist across navigations)
    @StateObject private var bvNotesViewModel = BVNotesViewModel()
    
    var body: some View {
        Form {
            Section(header: Text("Clinician Profile")) {
                TextField("Name", text: $appState.clinician.displayName)
                TextField("MCR Number", text: $appState.clinician.mcrNumber)
                
                Button("Save Profile") {
                    appState.saveClinician()
                }
            }
            
            Section(header: Text("Last Used Patient")) {
                if let patient = appState.lastUsedPatient {
                    Text("Name: \(patient.name)")
                    Text("NRIC: \(patient.nric)")
                } else {
                    Text("No patient data yet")
                        .foregroundColor(.secondary)
                }
            }
            
            // BV Notes settings lives in main Settings now
            Section(header: Text("BV Notes")) {
                NavigationLink {
                    // Reusable settings view from BV Notes
                    BVNotesSettingsView(viewModel: bvNotesViewModel)
                } label: {
                    HStack {
                        Image(systemName: "cross.case")
                        Text("BV Notes Settings")
                    }
                }
                Text("Configure global vaccine lot numbers and milestone templates used by BV Notes.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // New: Export/Import BV Notes settings bundled with coordinates
                if let adapter {
                    Button("Export coordinates + BV Notes settings") {
                        let json = makeCombinedExportJSON(templates: adapter.templates, bvSettings: bvNotesViewModel.globalSettings)
                        Clipboard.copy(json)
                        showingCopiedAlert = true
                    }
                    Button("Import coordinates + BV Notes settings") {
                        showingImport = true
                    }
                }
            }
            
            // Templates management and coordinate transfer live in the same section
            Section(header: Text("Templates")) {
                NavigationLink(destination: TemplateEditorView()) {
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
                
                // Existing Export coordinates row (templates only)
                Button("Export coordinates") {
                    guard let adapter else { return }
                    let json = makeExportJSON(from: adapter.templates)
                    Clipboard.copy(json)
                    showingCopiedAlert = true
                }
                
                // Existing Import coordinates row (templates only or combined; importer handles both)
                Button("Import coordinates") {
                    showingImport = true
                }
            }
            
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersionString())
                        .foregroundColor(.secondary)
                        .accessibilityLabel("App Version")
                }
                
                Text("Speedoc Clinical Notes fills PDF forms from image templates. Exports flattened PDFs with specific filenames.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        // Create the adapter once when the view appears
        .onAppear {
            if adapter == nil {
                adapter = AppStateTemplateAdapter(appState: appState)
            }
        }
        // Export alert
        .alert("Copied", isPresented: $showingCopiedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Export JSON copied to clipboard.")
        }
        // Import sheet – uses existing importer which now also saves BV Notes settings if present
        .sheet(isPresented: $showingImport) {
            if let adapter {
                ImportCoordinatesSheet<AppStateTemplateAdapter>()
                    .environmentObject(adapter)
                    .onDisappear {
                        // Reload BV settings from disk in case an import updated them
                        if let loaded = BVNotesViewModel.loadGlobalSettings() {
                            bvNotesViewModel.globalSettings = loaded
                        }
                    }
            } else {
                // Fallback: if adapter isn’t ready, show a spinner briefly
                ProgressView()
                    .onAppear {
                        if adapter == nil {
                            adapter = AppStateTemplateAdapter(appState: appState)
                        }
                    }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func appVersionString() -> String {
        let marketing = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(marketing) (\(build))"
    }
}

#Preview {
    NavigationView {
        SettingsView()
            .environmentObject(AppState())
    }
}
