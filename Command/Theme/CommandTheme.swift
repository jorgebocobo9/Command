import SwiftUI

struct CommandTheme: ViewModifier {
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(.dark)
            .tint(CommandColors.school)
    }
}

extension View {
    func commandTheme() -> some View {
        modifier(CommandTheme())
    }
}
