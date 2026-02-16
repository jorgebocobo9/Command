import SwiftUI

struct CommandTheme: ViewModifier {
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(.dark)
            .tint(CommandColors.school)
            .background(CommandColors.background.ignoresSafeArea())
    }
}

struct CommandCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(CommandColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(CommandColors.surfaceBorder, lineWidth: 0.5)
            )
    }
}

extension View {
    func commandTheme() -> some View {
        modifier(CommandTheme())
    }

    func commandCard(cornerRadius: CGFloat = 12) -> some View {
        modifier(CommandCardModifier(cornerRadius: cornerRadius))
    }
}
