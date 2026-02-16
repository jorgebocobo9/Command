import SwiftUI

struct MissionCard: View {
    let mission: Mission
    let onTap: () -> Void

    var body: some View {
        Button {
            Haptic.selection()
            onTap()
        } label: {
            HStack(spacing: 12) {
                // Category indicator bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(CommandColors.categoryColor(mission.category))
                    .frame(width: 4, height: 48)

                VStack(alignment: .leading, spacing: 6) {
                    Text(mission.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(CommandColors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 10) {
                        if let minutes = mission.estimatedMinutes {
                            Label("\(minutes)m", systemImage: "clock")
                                .font(CommandTypography.caption)
                                .foregroundStyle(CommandColors.textTertiary)
                        }

                        if !mission.steps.isEmpty {
                            Label("\(mission.steps.filter(\.isCompleted).count)/\(mission.steps.count)", systemImage: "list.bullet")
                                .font(CommandTypography.caption)
                                .foregroundStyle(CommandColors.textTertiary)
                        }

                        if let deadline = mission.deadline {
                            Text(deadline, style: .relative)
                                .font(CommandTypography.caption)
                                .foregroundStyle(mission.isOverdue ? CommandColors.urgent : CommandColors.textTertiary)
                        }
                    }
                }

                Spacer()

                AggressionBadge(level: mission.aggressionLevel)

                // Step progress
                if !mission.steps.isEmpty {
                    CircularProgressView(progress: mission.stepProgress, color: CommandColors.categoryColor(mission.category))
                        .frame(width: 30, height: 30)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(CommandColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(mission.isOverdue ? CommandColors.urgent.opacity(0.3) : CommandColors.surfaceBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.12), lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}
