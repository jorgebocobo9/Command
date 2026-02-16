import SwiftUI

struct HeatmapView: View {
    let profiles: [EnergyProfile]

    private let hours = Array(0..<24)
    private let days = ["S", "M", "T", "W", "T", "F", "S"]
    private let cellSize: CGFloat = 14
    private let spacing: CGFloat = 2

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("PRODUCTIVITY HEATMAP")

            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: spacing) {
                    // Hour labels
                    HStack(spacing: spacing) {
                        Text("")
                            .frame(width: 16)
                        ForEach(hours, id: \.self) { hour in
                            if hour % 3 == 0 {
                                Text("\(hour)")
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundStyle(CommandColors.textTertiary)
                                    .frame(width: cellSize)
                            } else {
                                Text("")
                                    .frame(width: cellSize)
                            }
                        }
                    }

                    // Grid
                    ForEach(1...7, id: \.self) { day in
                        HStack(spacing: spacing) {
                            Text(days[day - 1])
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(CommandColors.textTertiary)
                                .frame(width: 16)

                            ForEach(hours, id: \.self) { hour in
                                let productivity = profileValue(hour: hour, day: day)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(cellColor(productivity))
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }

            // Legend
            HStack(spacing: 4) {
                Text("Less")
                    .font(.system(size: 9))
                    .foregroundStyle(CommandColors.textTertiary)
                ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(cellColor(level))
                        .frame(width: 10, height: 10)
                }
                Text("More")
                    .font(.system(size: 9))
                    .foregroundStyle(CommandColors.textTertiary)
            }
        }
        .commandCard()
    }

    private func profileValue(hour: Int, day: Int) -> Double {
        profiles.first { $0.hourOfDay == hour && $0.dayOfWeek == day }?.averageProductivity ?? 0
    }

    private func cellColor(_ value: Double) -> Color {
        if value <= 0 { return CommandColors.surfaceElevated }
        return CommandColors.school.opacity(0.2 + value * 0.8)
    }
}
