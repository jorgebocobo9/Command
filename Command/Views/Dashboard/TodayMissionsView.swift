import SwiftUI

struct TodayMissionsView: View {
    let missions: [Mission]
    let energyLevel: Double
    var onCreateTap: (() -> Void)? = nil
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
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(CommandColors.school.opacity(0.06))
                            .frame(width: 72, height: 72)
                        Image(systemName: "checkmark.seal")
                            .font(.system(size: 32, weight: .thin))
                            .foregroundStyle(CommandColors.school.opacity(0.5))
                    }

                    Text("All clear")
                        .font(CommandTypography.headline)
                        .foregroundStyle(CommandColors.textSecondary)

                    Text("No missions due today. Create one to get started.")
                        .font(CommandTypography.caption)
                        .foregroundStyle(CommandColors.textTertiary)
                        .multilineTextAlignment(.center)

                    if let onCreateTap {
                        Button(action: onCreateTap) {
                            Text("New Mission")
                                .font(CommandTypography.caption)
                                .foregroundStyle(CommandColors.textPrimary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(CommandColors.school.opacity(0.15))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(CommandColors.school.opacity(0.3), lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(missions, id: \.id) { mission in
                    MissionCard(mission: mission) {
                        onMissionTap(mission)
                    }
                }
            }
        }
        .padding(16)
        .background(CommandColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(CommandColors.surfaceBorder, lineWidth: 0.5)
        )
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
