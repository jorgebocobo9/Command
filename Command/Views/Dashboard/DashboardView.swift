import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Query private var allMissions: [Mission]
    @Query private var streaks: [Streak]
    @State private var selectedMission: Mission?
    @State private var showCreateMission = false

    private let energyService = EnergyService()

    private var activeMissions: [Mission] {
        allMissions.filter { $0.status != .completed && $0.status != .abandoned }
    }

    private var todayMissions: [Mission] {
        let calendar = Calendar.current
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
        let todayRaw = activeMissions.filter { mission in
            guard let deadline = mission.deadline else { return false }
            return deadline <= endOfDay
        }
        return energyService.suggestMissionOrder(todayRaw, context: context)
    }

    private var currentEnergy: Double {
        energyService.currentEnergyLevel(context: context)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Late night"
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            CommandColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Header with greeting
                    VStack(alignment: .leading, spacing: 4) {
                        Text(greeting)
                            .font(CommandTypography.title)
                            .foregroundStyle(CommandColors.textPrimary)

                        Text(Date(), format: .dateTime.weekday(.wide).month().day())
                            .font(CommandTypography.caption)
                            .foregroundStyle(CommandColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)

                    // Pressure Radar
                    PressureRadarView(
                        missions: activeMissions
                    ) { mission in
                        selectedMission = mission
                    }
                    .padding(.horizontal, 16)

                    // Today's Missions
                    TodayMissionsView(
                        missions: todayMissions,
                        energyLevel: currentEnergy,
                        onCreateTap: { showCreateMission = true }
                    ) { mission in
                        selectedMission = mission
                    }
                    .padding(.horizontal, 16)

                    // Momentum Strip
                    MomentumStripView(streaks: streaks)
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, 80)
            }
            .scrollContentBackground(.hidden)

            // Floating Action Button
            Button {
                Haptic.impact(.medium)
                showCreateMission = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(CommandColors.textPrimary)
                    .frame(width: 56, height: 56)
                    .background(CommandColors.school.opacity(0.25))
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(CommandColors.school.opacity(0.4), lineWidth: 1)
                    )
                    .glow(CommandColors.school, radius: 10, intensity: 0.3)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .sheet(item: $selectedMission) { mission in
            MissionDetailView(mission: mission)
        }
        .sheet(isPresented: $showCreateMission) {
            CreateMissionView()
        }
    }
}
