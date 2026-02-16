import SwiftUI

struct AggressionBadge: View {
    let level: AggressionLevel

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(barColor)
                    .frame(width: 3, height: CGFloat(6 + index * 3))
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(barColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var barCount: Int {
        switch level {
        case .gentle: return 1
        case .moderate: return 2
        case .aggressive: return 3
        case .nuclear: return 4
        }
    }

    private var barColor: Color {
        switch level {
        case .gentle: return CommandColors.success
        case .moderate: return CommandColors.warning
        case .aggressive: return CommandColors.urgent
        case .nuclear: return CommandColors.urgent
        }
    }
}
