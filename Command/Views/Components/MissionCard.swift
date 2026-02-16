import SwiftUI

struct MissionCard: View {
    let mission: Mission
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Category indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(CommandColors.categoryColor(mission.category))
                    .frame(width: 4, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(mission.title)
                        .font(CommandTypography.headline)
                        .foregroundStyle(CommandColors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        if let minutes = mission.estimatedMinutes {
                            Label("\(minutes)m", systemImage: "clock")
                                .font(CommandTypography.caption)
                                .foregroundStyle(CommandColors.textSecondary)
                        }

                        if !mission.steps.isEmpty {
                            Text("\(mission.steps.filter(\.isCompleted).count)/\(mission.steps.count)")
                                .font(CommandTypography.caption)
                                .foregroundStyle(CommandColors.textSecondary)
                        }

                        if let deadline = mission.deadline {
                            Text(deadline, style: .relative)
                                .font(CommandTypography.caption)
                                .foregroundStyle(mission.isOverdue ? CommandColors.urgent : CommandColors.textSecondary)
                        }
                    }
                }

                Spacer()

                AggressionBadge(level: mission.aggressionLevel)

                // Step progress
                if !mission.steps.isEmpty {
                    CircularProgressView(progress: mission.stepProgress, color: CommandColors.categoryColor(mission.category))
                        .frame(width: 28, height: 28)
                }
            }
            .padding(12)
            .background(CommandColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
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
                .stroke(color.opacity(0.15), lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}
