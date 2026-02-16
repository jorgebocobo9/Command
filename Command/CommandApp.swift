import SwiftUI
import SwiftData

@main
struct CommandApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Mission.self,
            MissionStep.self,
            Resource.self,
            FocusSession.self,
            EnergyProfile.self,
            Streak.self,
            ClassroomCourse.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Dashboard", systemImage: "gauge.open.with.lines.needle.33percent", value: 0) {
                DashboardView()
            }
            Tab("Missions", systemImage: "target", value: 1) {
                MissionListView()
            }
            Tab("Classroom", systemImage: "graduationcap", value: 2) {
                ClassroomView()
            }
            Tab("Focus", systemImage: "scope", value: 3) {
                FocusLauncherView()
            }
            Tab("Intel", systemImage: "chart.bar.xaxis.ascending", value: 4) {
                IntelView()
            }
        }
        .commandTheme()
    }
}

struct FocusLauncherView: View {
    @Query private var allMissions: [Mission]
    private var activeMissions: [Mission] {
        allMissions.filter { $0.status != .completed && $0.status != .abandoned }
    }

    @State private var selectedMission: Mission?

    var body: some View {
        NavigationStack {
            ZStack {
                CommandColors.background.ignoresSafeArea()

                if activeMissions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "scope")
                            .font(.system(size: 48, weight: .thin))
                            .foregroundStyle(CommandColors.textTertiary)
                        Text("No active missions")
                            .font(CommandTypography.headline)
                            .foregroundStyle(CommandColors.textSecondary)
                        Text("Create a mission first, then start a focus session")
                            .font(CommandTypography.caption)
                            .foregroundStyle(CommandColors.textTertiary)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("SELECT MISSION TO FOCUS")
                                .font(CommandTypography.caption)
                                .foregroundStyle(CommandColors.textTertiary)
                                .tracking(1.5)
                                .padding(.horizontal)

                            ForEach(activeMissions, id: \.id) { mission in
                                MissionCard(mission: mission) {
                                    selectedMission = mission
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top)
                    }
                }
            }
            .navigationTitle("Focus")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .fullScreenCover(item: $selectedMission) { mission in
                FocusSessionView(mission: mission)
            }
        }
    }
}
