import SwiftUI

struct AggressionSlider: View {
    @Binding var level: AggressionLevel
    @State private var isDragging = false

    private let levels = AggressionLevel.allCases

    private var currentIndex: Int {
        levels.firstIndex(of: level) ?? 0
    }

    private func color(for level: AggressionLevel) -> Color {
        switch level {
        case .gentle: return CommandColors.success
        case .moderate: return CommandColors.warning
        case .aggressive: return Color(hex: "FF5533")
        case .nuclear: return CommandColors.urgent
        }
    }

    private func label(for level: AggressionLevel) -> String {
        level.rawValue.capitalized
    }

    var body: some View {
        VStack(spacing: 10) {
            // Segmented track
            GeometryReader { geo in
                let segmentWidth = geo.size.width / CGFloat(levels.count)

                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(CommandColors.surfaceElevated)

                    // Active segment highlight
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color(for: level).opacity(0.2))
                        .frame(width: segmentWidth)
                        .offset(x: CGFloat(currentIndex) * segmentWidth)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(color(for: level).opacity(0.4), lineWidth: 1)
                                .frame(width: segmentWidth)
                                .offset(x: CGFloat(currentIndex) * segmentWidth),
                            alignment: .leading
                        )

                    // Segments
                    HStack(spacing: 0) {
                        ForEach(Array(levels.enumerated()), id: \.element) { index, lvl in
                            Button {
                                Haptic.selection()
                                withAnimation(CommandAnimations.springQuick) {
                                    level = lvl
                                }
                            } label: {
                                VStack(spacing: 3) {
                                    // Signal bars
                                    HStack(spacing: 2) {
                                        ForEach(0..<(index + 1), id: \.self) { bar in
                                            RoundedRectangle(cornerRadius: 1)
                                                .fill(lvl == level ? color(for: lvl) : CommandColors.textTertiary.opacity(0.4))
                                                .frame(width: 3, height: CGFloat(4 + bar * 2))
                                        }
                                    }
                                    .frame(height: 10, alignment: .bottom)

                                    Text(label(for: lvl))
                                        .font(.system(size: 9, weight: lvl == level ? .bold : .medium))
                                        .foregroundStyle(lvl == level ? color(for: lvl) : CommandColors.textTertiary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(height: 44)

            // Description of current level
            Text(sublabel(for: level))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(CommandColors.textTertiary)
                .animation(.none, value: level)
        }
    }

    private func sublabel(for level: AggressionLevel) -> String {
        switch level {
        case .gentle: return "1 reminder, 24h before deadline"
        case .moderate: return "5 reminders with escalating urgency"
        case .aggressive: return "8 reminders, intense tone"
        case .nuclear: return "Non-stop reminders until done"
        }
    }
}
