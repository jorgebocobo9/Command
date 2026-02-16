import SwiftUI

struct TaskDNAChartView: View {
    let missions: [Mission]

    private var completedMissions: [Mission] {
        missions.filter { $0.status == .completed && $0.estimatedMinutes != nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("TASK DNA")

            Text("Estimated vs Actual Time")
                .font(CommandTypography.caption)
                .foregroundStyle(CommandColors.textSecondary)

            if completedMissions.isEmpty {
                Text("Complete tasks with estimates to see accuracy")
                    .font(CommandTypography.body)
                    .foregroundStyle(CommandColors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(completedMissions.suffix(8), id: \.id) { mission in
                        DNABarRow(mission: mission)
                    }
                }

                // Accuracy summary
                if let accuracy = overallAccuracy {
                    HStack {
                        Spacer()
                        Text("Avg accuracy: \(Int(accuracy * 100))%")
                            .font(CommandTypography.caption)
                            .foregroundStyle(accuracy > 0.7 ? CommandColors.success : CommandColors.warning)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .commandCard()
    }

    private var overallAccuracy: Double? {
        let valid = completedMissions.filter { $0.estimatedMinutes != nil && $0.totalActualMinutes > 0 }
        guard !valid.isEmpty else { return nil }

        let totalRatio = valid.reduce(0.0) { sum, mission in
            let estimated = Double(mission.estimatedMinutes ?? 0)
            let actual = Double(mission.totalActualMinutes)
            guard estimated > 0, actual > 0 else { return sum }
            return sum + min(estimated, actual) / max(estimated, actual)
        }
        return totalRatio / Double(valid.count)
    }
}

struct DNABarRow: View {
    let mission: Mission

    private var estimated: Double { Double(mission.estimatedMinutes ?? 0) }
    private var actual: Double { Double(mission.totalActualMinutes) }
    private var maxValue: Double { max(estimated, actual, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(mission.title)
                .font(CommandTypography.caption)
                .foregroundStyle(CommandColors.textSecondary)
                .lineLimit(1)

            GeometryReader { geo in
                VStack(spacing: 2) {
                    // Estimated bar
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(CommandColors.school.opacity(0.6))
                            .frame(width: geo.size.width * (estimated / maxValue), height: 6)
                        if estimated > 0 {
                            Text("\(Int(estimated))m")
                                .font(.system(size: 8))
                                .foregroundStyle(CommandColors.textTertiary)
                        }
                    }

                    // Actual bar
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(CommandColors.categoryColor(mission.category))
                            .frame(width: actual > 0 ? geo.size.width * (actual / maxValue) : 0, height: 6)
                        if actual > 0 {
                            Text("\(Int(actual))m")
                                .font(.system(size: 8))
                                .foregroundStyle(CommandColors.textTertiary)
                        }
                    }
                }
            }
            .frame(height: 16)
        }
    }
}
