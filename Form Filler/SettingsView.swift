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
                
                // Export coordinates row
                Button("Export coordinates") {
                    guard let adapter else { return }
                    let json = makeExportJSON(from: adapter.templates)
                    Clipboard.copy(json)
                    showingCopiedAlert = true
                }
                
                // Import coordinates row
                Button("Import coordinates") {
                    showingImport = true
                }
            }
            
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0")
                        .foregroundColor(.secondary)
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
            Text("Template coordinates copied to clipboard.")
        }
        // Import sheet – pass the same store environment object
        .sheet(isPresented: $showingImport) {
            if let adapter {
                ImportCoordinatesSheet<AppStateTemplateAdapter>()
                    .environmentObject(adapter)
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
}

#Preview {
    NavigationView {
        SettingsView()
            .environmentObject(AppState())
    }
}
