//
//  HomeView.swift
//  Speedoc Clinical Notes
//
//  Main home screen with navigation to forms and settings
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingClinicianSetup = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Watercolor-like paper background
                TexturedPaperBackground()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text("Clinical Notes")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("PDF Form Filler")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                        
                        // Institution Buttons (textured)
                        VStack(spacing: 16) {
                            Text("Select Institution")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            // Active Global
                            NavigationLink {
                                InstitutionFormListView(institution: .activeGlobal)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: Institution.activeGlobal.iconName)
                                        .imageScale(.large)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(Institution.activeGlobal.displayName)
                                        Text(Institution.activeGlobal.subtitle)
                                            .font(.subheadline)
                                            .opacity(0.9)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.headline)
                                }
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity, minHeight: 68)
                            }
                            .buttonStyle(TexturedButtonStyle(institution: .activeGlobal))
                            
                            // Lentor
                            NavigationLink {
                                InstitutionFormListView(institution: .lentor)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: Institution.lentor.iconName)
                                        .imageScale(.large)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(Institution.lentor.displayName)
                                        Text(Institution.lentor.subtitle)
                                            .font(.subheadline)
                                            .opacity(0.9)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.headline)
                                }
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity, minHeight: 68)
                            }
                            .buttonStyle(TexturedButtonStyle(institution: .lentor))
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 40)
                        
                        // Settings Link (kept simple; you can also style it)
                        NavigationLink(destination: SettingsView()) {
                            HStack {
                                Image(systemName: "gear")
                                Text("Settings")
                            }
                            .foregroundColor(.blue)
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                checkClinicianSetup()
            }
            .sheet(isPresented: $showingClinicianSetup) {
                ClinicianSetupView(isPresented: $showingClinicianSetup)
            }
        }
        #if os(iOS)
        .navigationViewStyle(StackNavigationViewStyle())
        #endif
    }
    
    private func checkClinicianSetup() {
        if appState.clinician.displayName.isEmpty {
            showingClinicianSetup = true
        }
    }
}

// MARK: - Institution Card (unchanged; no longer used on Home, but keep for other screens)

struct InstitutionCard: View {
    let institution: Institution
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: institution.iconName)
                    .font(.title)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(institution.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(institution.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .background(LinearGradient(
            colors: [Color.blue, Color.blue.opacity(0.8)],
            startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Clinician Setup Sheet (unchanged)

struct ClinicianSetupView: View {
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool
    
    @State private var name = ""
    @State private var mcr = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Welcome! Set up your profile")) {
                    TextField("Your Name", text: $name)
                    TextField("MCR Number", text: $mcr)
                }
                
                Section {
                    Button("Save") {
                        appState.clinician.displayName = name
                        appState.clinician.mcrNumber = mcr
                        appState.saveClinician()
                        isPresented = false
                    }
                    .disabled(name.isEmpty || mcr.isEmpty)
                }
            }
            .navigationTitle("Clinician Setup")
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(appState.clinician.displayName.isEmpty)
    }
}

// Keep ContentView for compatibility
struct ContentView: View {
    var body: some View {
        HomeView()
    }
}

#Preview("Home View") {
    // Prepare an AppState with a filled clinician to avoid showing the setup sheet in preview
    let previewState = AppState()
    previewState.clinician.displayName = "Preview Doctor"
    previewState.clinician.mcrNumber = "M12345Z"
    return HomeView()
        .environmentObject(previewState)
}

#Preview("Clinician Setup") {
    let state = AppState()
    // Keep empty to demonstrate disabled interactive dismiss when name is empty
    state.clinician.displayName = ""
    state.clinician.mcrNumber = ""
    return ClinicianSetupView(isPresented: .constant(true))
        .environmentObject(state)
}
