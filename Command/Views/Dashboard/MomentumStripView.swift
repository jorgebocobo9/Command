import SwiftUI

struct MomentumStripView: View {
    let streaks: [Streak]
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(CommandAnimations.spring) { expanded.toggle() }
            } label: {
                HStack {
                    Text("MOMENTUM")
                        .font(CommandTypography.caption)
                        .foregroundStyle(CommandColors.textTertiary)
                        .tracking(1.5)

                    Spacer()

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(CommandColors.textTertiary)
                }
            }
            .buttonStyle(.plain)

            HStack(spacing: 16) {
                ForEach(streaks.filter { $0.category != .overall }, id: \.category) { streak in
                    StreakBar(streak: streak)
                }
            }

            if expanded, let overall = streaks.first(where: { $0.category == .overall }) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Overall")
                            .font(CommandTypography.caption)
                            .foregroundStyle(CommandColors.textSecondary)
                        Spacer()
                        Text("\(overall.currentCount) day streak")
                            .font(CommandTypography.caption)
                            .foregroundStyle(CommandColors.textPrimary)
                    }
                    Text("Best: \(overall.longestCount) days")
                        .font(CommandTypography.caption)
                        .foregroundStyle(CommandColors.textTertiary)
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(CommandColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(CommandColors.surfaceBorder, lineWidth: 0.5)
        )
    }
}

struct StreakBar: View {
    let streak: Streak
    @State private var animatedWidth: CGFloat = 0

    private var color: Color {
        switch streak.category {
        case .school: return CommandColors.school
        case .work: return CommandColors.work
        case .personal: return CommandColors.personal
        case .overall: return CommandColors.textPrimary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(streak.category.rawValue.capitalized)
                    .font(CommandTypography.caption)
                    .foregroundStyle(CommandColors.textSecondary)

                if streak.currentCount >= 3 {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(CommandColors.warning)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.15))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: animatedWidth, height: 4)
                        .glow(color, radius: 4, intensity: streak.momentumScore)
                }
                .onAppear {
                    withAnimation(CommandAnimations.spring.delay(0.2)) {
                        let maxWidth = geo.size.width
                        animatedWidth = maxWidth * min(streak.momentumScore, 1.0)
                    }
                }
            }
            .frame(height: 4)

            Text("\(streak.currentCount)")
                .font(CommandTypography.mono)
                .foregroundStyle(color)
        }
    }
}
