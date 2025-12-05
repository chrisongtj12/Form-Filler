//
//  ContentView+BVEntry.swift
//  Speedoc Clinical Notes
//
//  BV Notes entry point card for the home screen
//

import SwiftUI

extension HomeView {
    /// Add this to your HomeView body to include BV Notes
    var bvNotesCard: some View {
        NavigationLink {
            BVNotesView()
        } label: {
            HStack {
                Image(systemName: "cross.case.fill")
                    .foregroundColor(.blue)
                
                Text("Baby Vaccination Notes")
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("BV Notes")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
    }
}

// MARK: - Preview

#Preview("BV Notes Card") {
    NavigationView {
        ScrollView {
            VStack(spacing: 16) {
                HomeView().bvNotesCard
            }
            .padding()
        }
    }
    .environmentObject(AppState())
}
