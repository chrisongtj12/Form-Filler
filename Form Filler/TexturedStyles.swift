// TexturedStyles.swift
// Shared background and button styles used in HomeView.

import SwiftUI

// MARK: - Textured Paper Background

struct TexturedPaperBackground: View {
    var body: some View {
        // Subtle paper-like effect using layered gradients and noise
        ZStack {
            // Base warm paper tone
            LinearGradient(
                colors: [
                    Color(white: 0.98),
                    Color(white: 0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            // Soft vignette to draw focus toward center
            RadialGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.04), Color.clear]),
                center: .center,
                startRadius: 0,
                endRadius: 700
            )
            // Very subtle noise overlay to avoid flat color feel
            Color.white
                .blendMode(.overlay)
                .opacity(0.2)
                .overlay(
                    // Use a system symbol as a tiny repeating texture if no asset is available.
                    // This is super subtle; replace with a real noise image for higher quality if desired.
                    GeometryReader { geo in
                        let size: CGFloat = 8
                        let cols = Int(geo.size.width / size)
                        let rows = Int(geo.size.height / size)
                        Canvas { context, _ in
                            let rect = CGRect(x: 0, y: 0, width: size, height: size)
                            for x in 0..<cols {
                                for y in 0..<rows {
                                    let alpha = 0.006 + Double.random(in: -0.003...0.003)
                                    context.fill(
                                        Path(rect.insetBy(dx: 3.5, dy: 3.5).offsetBy(dx: CGFloat(x) * size, dy: CGFloat(y) * size)),
                                        with: .color(.black.opacity(alpha))
                                    )
                                }
                            }
                        }
                    }
                )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Textured Button Style

struct TexturedButtonStyle: ButtonStyle {
    enum Palette {
        case activeGlobal
        case lentor
        
        init(institution: Institution) {
            switch institution {
            case .activeGlobal: self = .activeGlobal
            case .lentor: self = .lentor
            }
        }
        
        var base: Color {
            switch self {
            case .activeGlobal: return Color.blue
            case .lentor: return Color.green
            }
        }
        
        var highlight: Color {
            switch self {
            case .activeGlobal: return Color.blue.opacity(0.85)
            case .lentor: return Color.green.opacity(0.85)
            }
        }
        
        var shadow: Color {
            switch self {
            case .activeGlobal: return Color.blue.opacity(0.35)
            case .lentor: return Color.green.opacity(0.35)
            }
        }
    }
    
    private let palette: Palette
    
    // Convenience init to accept Institution directly (matches usage intent).
    init(palette: Institution) {
        self.palette = Palette(institution: palette)
    }
    
    // Also allow explicit palette if ever needed.
    init(palette: Palette) {
        self.palette = palette
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    // Gradient background for depth
                    LinearGradient(
                        colors: [
                            palette.base,
                            palette.highlight
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    // Subtle inner highlight
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                        .blendMode(.overlay)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: palette.shadow, radius: 6, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Textured Background") {
    ZStack {
        TexturedPaperBackground()
        VStack(spacing: 20) {
            Button {
            } label: {
                HStack {
                    Image(systemName: "building.2.fill")
                    Text("Active Global")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 68)
            }
            .buttonStyle(TexturedButtonStyle(palette: .activeGlobal))
            .padding(.horizontal, 20)
            
            Button {
            } label: {
                HStack {
                    Image(systemName: "building.fill")
                    Text("Lentor")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 68)
            }
            .buttonStyle(TexturedButtonStyle(palette: .lentor))
            .padding(.horizontal, 20)
        }
    }
}
