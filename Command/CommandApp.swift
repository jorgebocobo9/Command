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
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    // Urgent/Nuclear overlay state
    @Query private var allMissions: [Mission]
    @State private var showNuclearInterstitial = false
    @State private var nuclearMission: Mission?
    @State private var showUrgentBanner = false
    @State private var urgentBannerMission: Mission?
    @State private var selectedUrgentMission: Mission?

    // Auto-sync
    @State private var classroomVM = ClassroomViewModel()
    @Environment(\.modelContext) private var context

    private var overdueMissions: [Mission] {
        allMissions.filter { $0.isOverdue && $0.status != .completed && $0.status != .abandoned }
    }

    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView {
                hasCompletedOnboarding = true
            }
        } else {
            ZStack(alignment: .top) {
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
                .tabViewStyle(.tabBarOnly)
                .preferredColorScheme(.dark)
                .tint(CommandColors.school)

                // Urgent banner overlay at top
                if showUrgentBanner, let mission = urgentBannerMission {
                    UrgentBannerView(
                        mission: mission,
                        onTap: {
                            selectedUrgentMission = mission
                            withAnimation { showUrgentBanner = false }
                        },
                        onDismiss: {
                            withAnimation { showUrgentBanner = false }
                        }
                    ).show()
                    .padding(.top, 60)
                    .zIndex(100)
                }
            }
            .fullScreenCover(isPresented: $showNuclearInterstitial) {
                if let mission = nuclearMission {
                    NuclearInterstitialView(mission: mission) {
                        showNuclearInterstitial = false
                    }
                }
            }
            .sheet(item: $selectedUrgentMission) { mission in
                MissionDetailView(mission: mission)
            }
            .task {
                // Request notification permission and register categories
                await NotificationService.shared.registerCategories()
                _ = await NotificationService.shared.requestPermission()

                // Auto-sync Classroom if connected and last sync > 1 hour ago
                if classroomVM.isConnected {
                    let oneHourAgo = Date().addingTimeInterval(-3600)
                    if classroomVM.lastSynced == nil || classroomVM.lastSynced! < oneHourAgo {
                        await classroomVM.sync(context: context)
                    }
                }

                // Check for urgent/nuclear overdue missions
                checkForUrgentMissions()
            }
        }
    }

    private func checkForUrgentMissions() {
        // Nuclear overdue → full-screen interstitial
        if let nuclear = overdueMissions.first(where: { $0.aggressionLevel == .nuclear }) {
            nuclearMission = nuclear
            showNuclearInterstitial = true
            return
        }

        // Aggressive overdue → banner
        if let aggressive = overdueMissions.first(where: { $0.aggressionLevel == .aggressive }) {
            urgentBannerMission = aggressive
            withAnimation { showUrgentBanner = true }
        }
    }
}

struct FocusLauncherView: View {
    @Query private var allMissions: [Mission]
    private var activeMissions: [Mission] {
        allMissions.filter { $0.status != .completed && $0.status != .abandoned }
    }

    @State private var selectedMission: Mission?

    var body: some View {
        ZStack {
            CommandColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        Text("FOCUS")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(CommandColors.textPrimary)
                            .tracking(3)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)

                    if activeMissions.isEmpty {
                        EmptyStateView(
                            icon: "scope",
                            title: "No active missions",
                            subtitle: "Create a mission first, then start a focus session."
                        )
                        .padding(.top, 40)
                    } else {
                        Text("SELECT MISSION TO FOCUS")
                            .font(CommandTypography.caption)
                            .foregroundStyle(CommandColors.textTertiary)
                            .tracking(1.5)
                            .padding(.horizontal, 16)

                        ForEach(activeMissions, id: \.id) { mission in
                            MissionCard(mission: mission) {
                                selectedMission = mission
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .scrollContentBackground(.hidden)
        }
        .fullScreenCover(item: $selectedMission) { mission in
            FocusSessionView(mission: mission)
        }
    }
}
