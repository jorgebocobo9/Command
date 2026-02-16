import SwiftUI

struct TodayMissionsView: View {
    let missions: [Mission]
    let energyLevel: Double
    let onMissionTap: (Mission) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TODAY'S MISSIONS")
                    .font(CommandTypography.caption)
                    .foregroundStyle(CommandColors.textTertiary)
                    .tracking(1.5)

                Spacer()

                EnergyIndicator(level: energyLevel)
            }

            if missions.isEmpty {
                Text("No missions scheduled for today")
                    .font(CommandTypography.body)
                    .foregroundStyle(CommandColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(missions, id: \.id) { mission in
                    MissionCard(mission: mission) {
                        onMissionTap(mission)
                    }
                }
            }
        }
    }
}

struct EnergyIndicator: View {
    let level: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: level > 0.7 ? "bolt.fill" : level > 0.4 ? "bolt" : "bolt.slash")
                .font(.system(size: 10))
            Text(level > 0.7 ? "Peak focus" : level > 0.4 ? "Steady" : "Low energy")
                .font(CommandTypography.caption)
        }
        .foregroundStyle(level > 0.7 ? CommandColors.success : level > 0.4 ? CommandColors.textSecondary : CommandColors.warning)
    }
}
