//
//  ContentView.swift
//  Speedoc Clinical Notes
//
//  Main home screen with navigation to forms and settings
//

import SwiftUI

// MARK: - HomeView

struct HomeView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationView {
            List {
                // Templates section removed -- now lives in SettingsView

                Section {
                    bvNotesCard
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                
                Section(header: Text("Institutions")) {
                    ForEach(appState.institutions) { institution in
                        NavigationLink {
                            InstitutionFormListView(institution: institution)
                                .environmentObject(appState)
                        } label: {
                            HStack {
                                Image(systemName: institution.iconName)
                                Text(institution.displayName)
                                Spacer()
                                Text(institution.subtitle)
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    NavigationLink {
                        InstitutionManagerView()
                            .environmentObject(appState)
                    } label: {
                        Label("Manage Institutions", systemImage: "building.2.crop.circle")
                            .foregroundColor(.accentColor)
                    }
                }

                // Tools now only keeps the editor link above; you can add more tools here later.

                // Settings
                Section(header: Text("Settings")) {
                    NavigationLink {
                        SettingsView()
                            .environmentObject(appState)
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .navigationTitle("Form Filler")
        }
    }
}

// MARK: - Template List View

struct TemplateListView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTemplate: Template?

    var body: some View {
        List {
            ForEach(appState.templates) { template in
                NavigationLink {
                    // Placeholder filler; replace with your generic form filler when ready
                    TemplateActionsView(template: template)
                        .environmentObject(appState)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                        Text("Page \(template.pageIndex) • \(template.fields.count) fields")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Templates")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Template Actions View

struct TemplateActionsView: View {
    @EnvironmentObject var appState: AppState
    let template: Template

    var body: some View {
        Form {
            Section(header: Text("Selected Template")) {
                Text(template.name)
                Text("Page \(template.pageIndex)")
                Text("\(template.fields.count) fields")
            }
            Section {
                // Hook for your generic filler – swap this out when you implement it
                Button {
                    // TODO: navigate to your generic form filler view that uses `template`
                } label: {
                    Label("Fill this Template", systemImage: "doc.text")
                }

                NavigationLink {
                    // Open the editor and pre-select this template by index
                    EditorWrapperView(preselectTemplateID: template.id)
                        .environmentObject(appState)
                } label: {
                    Label("Edit this Template", systemImage: "square.and.pencil")
                }
            }
        }
        .navigationTitle("Template")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Helper to preselect the template in the editor
struct EditorWrapperView: View {
    @EnvironmentObject var appState: AppState
    let preselectTemplateID: UUID

    @State private var selectedIndex: Int = 0

    var body: some View {
        TemplateEditorView()
            .environmentObject(appState)
            .onAppear {
                if let idx = appState.templates.firstIndex(where: { $0.id == preselectTemplateID }) {
                    // Persist selection by reordering or by exposing selection binding in the editor.
                    // Since TemplateEditorView manages its own index, simplest is to reorder templates
                    // temporarily so the target appears first. Alternatively, expose selection via init.
                    selectedIndex = idx
                }
            }
    }
}

// MARK: - ContentView (wrapper)

struct ContentView: View {
    var body: some View {
        HomeView()
    }
}

// MARK: - Previews

#Preview("Home – Light") {
    let previewState = AppState()
    previewState.clinician.displayName = "Preview Doctor"
    previewState.clinician.mcrNumber = "M12345Z"
    return HomeView()
        .environmentObject(previewState)
        .preferredColorScheme(.light)
}

#Preview("Home – Dark") {
    let previewState = AppState()
    previewState.clinician.displayName = "Preview Doctor"
    previewState.clinician.mcrNumber = "M12345Z"
    return HomeView()
        .environmentObject(previewState)
        .preferredColorScheme(.dark)
}

#Preview("ContentView") {
    let previewState = AppState()
    previewState.clinician.displayName = "Preview Doctor"
    previewState.clinician.mcrNumber = "M12345Z"
    return ContentView()
        .environmentObject(previewState)
}

// MARK: - Additional Previews

#Preview("SettingsView") {
    let previewState = AppState()
    previewState.clinician.displayName = "Preview Doctor"
    previewState.clinician.mcrNumber = "M12345Z"
    return NavigationView {
        SettingsView()
            .environmentObject(previewState)
    }
}

#Preview("InstitutionFormListView (Active Global)") {
    let previewState = AppState()
    previewState.clinician.displayName = "Preview Doctor"
    previewState.clinician.mcrNumber = "M12345Z"
    return NavigationView {
        InstitutionFormListView(institution: .activeGlobal)
            .environmentObject(previewState)
    }
}

#Preview("InstitutionFormListView (Lentor)") {
    let previewState = AppState()
    previewState.clinician.displayName = "Preview Doctor"
    previewState.clinician.mcrNumber = "M12345Z"
    return NavigationView {
        InstitutionFormListView(institution: .lentor)
            .environmentObject(previewState)
    }
}

#Preview("TemplateEditorView") {
    let previewState = AppState()
    previewState.clinician.displayName = "Preview Doctor"
    previewState.clinician.mcrNumber = "M12345Z"
    return NavigationView {
        TemplateEditorView()
            .environmentObject(previewState)
    }
}

#Preview("MedicalNotesFormView") {
    let previewState = AppState()
    previewState.clinician.displayName = "Preview Doctor"
    previewState.clinician.mcrNumber = "M12345Z"
    return NavigationView {
        MedicalNotesFormView()
            .environmentObject(previewState)
    }
}
