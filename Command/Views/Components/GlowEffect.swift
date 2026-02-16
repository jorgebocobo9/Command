import SwiftUI

struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat
    let intensity: Double

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(intensity * 0.6), radius: radius * 0.5)
            .shadow(color: color.opacity(intensity * 0.3), radius: radius)
    }
}

struct PulsingGlow: ViewModifier {
    let color: Color
    let radius: CGFloat
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(isAnimating ? 0.6 : 0.2), radius: isAnimating ? radius : radius * 0.5)
            .onAppear {
                withAnimation(CommandAnimations.pulse) {
                    isAnimating = true
                }
            }
    }
}

extension View {
    func glow(_ color: Color, radius: CGFloat = 8, intensity: Double = 0.5) -> some View {
        modifier(GlowEffect(color: color, radius: radius, intensity: intensity))
    }

    func pulsingGlow(_ color: Color, radius: CGFloat = 12) -> some View {
        modifier(PulsingGlow(color: color, radius: radius))
    }
}
