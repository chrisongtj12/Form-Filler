//
//  Form_FillerApp_MP.swift
//  Speedoc Clinical Notes
//
//  This file is intentionally excluded from normal builds to avoid duplicate @main/AppState/TemplateManager.
//  If you need an alternate app entry for experiments, define the EXCLUDE_DUPLICATE_APP flag OFF and
//  add your alternate code here.
//

#if EXCLUDE_DUPLICATE_APP
import SwiftUI

@main
struct Form_FillerApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(appState)
                .onAppear {
                    appState.initializeDefaultsIfNeeded()
                }
        }
    }
}
#endif
