import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel = DashboardViewModel()
    @State private var selectedMission: Mission?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Pressure Radar
                    PressureRadarView(
                        missions: viewModel.allActiveMissions
                    ) { mission in
                        selectedMission = mission
                    }
                    .padding(.top, 8)

                    // Today's Missions
                    TodayMissionsView(
                        missions: viewModel.todayMissions,
                        energyLevel: viewModel.currentEnergy
                    ) { mission in
                        selectedMission = mission
                    }
                    .padding(.horizontal)

                    // Momentum Strip
                    MomentumStripView(streaks: viewModel.streaks)
                        .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .background(CommandColors.background)
            .navigationTitle("Command")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await viewModel.load(context: context)
            }
            .refreshable {
                await viewModel.load(context: context)
            }
            .sheet(item: $selectedMission) { mission in
                MissionDetailView(mission: mission)
            }
        }
    }
}
