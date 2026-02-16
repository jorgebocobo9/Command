import SwiftUI

struct PressureRadarView: View {
    let missions: [Mission]
    let onMissionTap: (Mission) -> Void

    @State private var appeared = false

    private let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let categories: [MissionCategory] = [.school, .work, .personal]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PRESSURE MAP")
                .font(CommandTypography.caption)
                .foregroundStyle(CommandColors.textTertiary)
                .tracking(1.5)

            // 7-day heatmap grid
            VStack(spacing: 4) {
                // Day labels
                HStack(spacing: 4) {
                    // Category label spacer
                    Color.clear.frame(width: 52, height: 12)

                    ForEach(0..<7, id: \.self) { dayOffset in
                        Text(dayLabel(for: dayOffset))
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(dayOffset == 0 ? CommandColors.textPrimary : CommandColors.textTertiary)
                            .frame(maxWidth: .infinity)
                    }
                }

                // Category rows
                ForEach(categories, id: \.self) { category in
                    HStack(spacing: 4) {
                        Text(category.rawValue.uppercased())
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundStyle(CommandColors.categoryColor(category).opacity(0.7))
                            .frame(width: 52, alignment: .leading)

                        ForEach(0..<7, id: \.self) { dayOffset in
                            let pressure = cellPressure(category: category, dayOffset: dayOffset)
                            let cellMissions = missionsFor(category: category, dayOffset: dayOffset)

                            PressureCell(
                                pressure: pressure,
                                missionCount: cellMissions.count,
                                color: CommandColors.categoryColor(category),
                                isToday: dayOffset == 0,
                                appeared: appeared
                            )
                            .onTapGesture {
                                if let first = cellMissions.first {
                                    onMissionTap(first)
                                }
                            }
                        }
                    }
                }
            }

            // Urgency summary bar
            HStack(spacing: 16) {
                urgencyStat(
                    count: missions.filter { $0.isOverdue }.count,
                    label: "OVERDUE",
                    color: CommandColors.urgent
                )
                urgencyStat(
                    count: missions.filter { dueTodayOrTomorrow($0) }.count,
                    label: "DUE SOON",
                    color: CommandColors.warning
                )
                urgencyStat(
                    count: missions.count,
                    label: "ACTIVE",
                    color: CommandColors.textSecondary
                )
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(CommandColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(CommandColors.surfaceBorder, lineWidth: 0.5)
        )
        .onAppear {
            withAnimation(CommandAnimations.spring.delay(0.2)) {
                appeared = true
            }
        }
    }

    private func dayLabel(for offset: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: offset, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    private func missionsFor(category: MissionCategory, dayOffset: Int) -> [Mission] {
        let calendar = Calendar.current
        let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: Date())!
        let startOfDay = calendar.startOfDay(for: targetDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return missions.filter { mission in
            guard mission.category == category else { return false }
            if dayOffset == 0 {
                // Today: include overdue + due today
                guard let deadline = mission.deadline else { return false }
                return deadline <= endOfDay
            } else {
                guard let deadline = mission.deadline else { return false }
                return deadline >= startOfDay && deadline < endOfDay
            }
        }
    }

    private func cellPressure(category: MissionCategory, dayOffset: Int) -> Double {
        let cellMissions = missionsFor(category: category, dayOffset: dayOffset)
        if cellMissions.isEmpty { return 0 }

        var pressure = Double(cellMissions.count) * 0.3

        for mission in cellMissions {
            if mission.isOverdue { pressure += 0.4 }
            switch mission.aggressionLevel {
            case .nuclear: pressure += 0.3
            case .aggressive: pressure += 0.2
            case .moderate: pressure += 0.1
            case .gentle: break
            }
        }

        return min(pressure, 1.0)
    }

    private func dueTodayOrTomorrow(_ mission: Mission) -> Bool {
        guard let deadline = mission.deadline else { return false }
        return deadline.timeIntervalSinceNow > 0 && deadline.timeIntervalSinceNow < 48 * 3600
    }

    private func urgencyStat(count: Int, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(count)")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(count > 0 ? color : CommandColors.textTertiary)
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(CommandColors.textTertiary)
                .tracking(0.5)
        }
    }
}

struct PressureCell: View {
    let pressure: Double
    let missionCount: Int
    let color: Color
    let isToday: Bool
    let appeared: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(cellColor)
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if missionCount > 0 {
                    Text("\(missionCount)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(pressure > 0.5 ? CommandColors.textPrimary : color.opacity(0.8))
                }
            }
            .overlay {
                if isToday {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(color.opacity(0.6), lineWidth: 1)
                }
            }
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.5)
    }

    private var cellColor: Color {
        if pressure <= 0 {
            return CommandColors.surfaceElevated.opacity(0.5)
        }
        return color.opacity(pressure * 0.7)
    }
}
