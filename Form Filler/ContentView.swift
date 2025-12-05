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
                // Solid adaptive background (no texture)
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
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
                        
                        // BV Notes (Baby Vaccination) Section
                        VStack(spacing: 16) {
                            Text("Clinical Notes Tools")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            // BV Notes card (blue gradient style defined in BVNotesButtonStyle)
                            bvNotesCard
                        }
                        .padding(.horizontal, 20)
                        
                        // Institution Buttons (override to GREEN)
                        VStack(spacing: 16) {
                            Text("Select Institution")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            // Active Global (green)
                            NavigationLink {
                                InstitutionFormListView(institution: .activeGlobal)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: Institution.activeGlobal.iconName)
                                        .imageScale(.large)
                                        .foregroundColor(.white)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(Institution.activeGlobal.displayName)
                                            .foregroundColor(.white)
                                        Text(Institution.activeGlobal.subtitle)
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.headline)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity, minHeight: 68)
                                .background(
                                    LinearGradient(
                                        colors: [Color.green, Color.green.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                            }
                            
                            // Lentor (green)
                            NavigationLink {
                                InstitutionFormListView(institution: .lentor)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: Institution.lentor.iconName)
                                        .imageScale(.large)
                                        .foregroundColor(.white)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(Institution.lentor.displayName)
                                            .foregroundColor(.white)
                                        Text(Institution.lentor.subtitle)
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.headline)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity, minHeight: 68)
                                .background(
                                    LinearGradient(
                                        colors: [Color.green, Color.green.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 40)
                        
                        // Settings Link
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
