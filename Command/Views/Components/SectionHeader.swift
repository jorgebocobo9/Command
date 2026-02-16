import SwiftUI

struct SectionHeader: View {
    let title: String
    var trailing: AnyView? = nil

    init(_ title: String) {
        self.title = title
    }

    init(_ title: String, @ViewBuilder trailing: () -> some View) {
        self.title = title
        self.trailing = AnyView(trailing())
    }

    var body: some View {
        HStack {
            Text(title)
                .font(CommandTypography.caption)
                .foregroundStyle(CommandColors.textTertiary)
                .tracking(1.5)

            Spacer()

            if let trailing {
                trailing
            }
        }
    }
}
