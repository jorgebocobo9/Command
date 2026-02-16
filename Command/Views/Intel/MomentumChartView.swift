import SwiftUI

struct MomentumChartView: View {
    let streaks: [Streak]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("MOMENTUM WAVES")

            if streaks.isEmpty {
                Text("Complete tasks to build momentum")
                    .font(CommandTypography.body)
                    .foregroundStyle(CommandColors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                HStack(spacing: 16) {
                    ForEach(streaks.filter { $0.category != .overall }, id: \.category) { streak in
                        VStack(spacing: 8) {
                            // Momentum bar
                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(streakColor(streak).opacity(0.1))
                                    .frame(width: 40, height: 80)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(streakColor(streak))
                                    .frame(width: 40, height: max(4, 80 * streak.momentumScore))
                                    .glow(streakColor(streak), radius: 4, intensity: streak.momentumScore)
                            }

                            Text(streak.category.rawValue.prefix(3).capitalized)
                                .font(CommandTypography.caption)
                                .foregroundStyle(CommandColors.textSecondary)

                            Text("\(streak.currentCount)d")
                                .font(CommandTypography.mono)
                                .foregroundStyle(streakColor(streak))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .commandCard()
    }

    private func streakColor(_ streak: Streak) -> Color {
        switch streak.category {
        case .school: return CommandColors.school
        case .work: return CommandColors.work
        case .personal: return CommandColors.personal
        case .overall: return CommandColors.textPrimary
        }
    }
}
