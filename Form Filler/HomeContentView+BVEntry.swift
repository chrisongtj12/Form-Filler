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
            HStack(spacing: 14) {
                Image(systemName: "cross.case.fill")
                    .imageScale(.large)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("BV Notes")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Baby Vaccination Notes")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 68)
        }
        .buttonStyle(BVNotesButtonStyle())
    }
}

// MARK: - BV Notes Button Style

struct BVNotesButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                ZStack {
                    // Change BV Notes to BLUE gradient
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    if configuration.isPressed {
                        Color.black.opacity(0.1)
                    }
                }
            )
            .cornerRadius(12)
            .shadow(
                color: .black.opacity(configuration.isPressed ? 0.05 : 0.15),
                radius: configuration.isPressed ? 3 : 8,
                x: 0,
                y: configuration.isPressed ? 1 : 4
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
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
