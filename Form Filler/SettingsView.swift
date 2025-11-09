//
//  SettingsView.swift
//  Speedoc Clinical Notes
//
//  Settings screen for profiles and template editing
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
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
    }
}
