import SwiftUI
import SwiftData
import UIKit
@preconcurrency import UserNotifications

// MARK: - App Delegate for Notification Handling

class AppDelegate: NSObject, UIApplicationDelegate, @unchecked Sendable {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Show notifications even when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    // Handle notification action buttons
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let actionId = response.actionIdentifier
        let missionId = response.notification.request.identifier.components(separatedBy: "-").first ?? ""

        switch actionId {
        case "COMPLETE_ACTION":
            await MainActor.run {
                NotificationCenter.default.post(name: .missionCompleteAction, object: nil, userInfo: ["missionId": missionId])
            }
        case "SNOOZE_ACTION":
            await NotificationService.shared.scheduleIntervalNotification(
                id: "\(missionId)-snooze-\(Date().timeIntervalSince1970)",
                title: "Snoozed reminder",
                body: "Time's up — get back to it.",
                interval: 15 * 60
            )
        case "START_FOCUS_ACTION":
            await MainActor.run {
                NotificationCenter.default.post(name: .missionFocusAction, object: nil, userInfo: ["missionId": missionId])
            }
        default:
            break
        }
    }
}

extension Notification.Name {
    static let missionCompleteAction = Notification.Name("missionCompleteAction")
    static let missionFocusAction = Notification.Name("missionFocusAction")
}

@main
struct CommandApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

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
                    Tab("Classroom", systemImage: "graduationcap", value: 1) {
                        ClassroomView()
                    }
                    Tab("Focus", systemImage: "scope", value: 2) {
                        FocusLauncherView()
                    }
                    Tab("Intel", systemImage: "chart.bar.xaxis.ascending", value: 3) {
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
            .fullScreenCover(item: $nuclearMission) { mission in
                NuclearInterstitialView(mission: mission) {
                    nuclearMission = nil
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

                // Small delay to let @Query reflect data
                try? await Task.sleep(for: .milliseconds(300))
                checkForUrgentMissions()
            }
            .onChange(of: allMissions.count) {
                // Re-check when missions update (catches async inserts)
                checkForUrgentMissions()
            }
        }
    }

    private func checkForUrgentMissions() {
        // Nuclear overdue → full-screen interstitial
        if let nuclear = overdueMissions.first(where: { $0.aggressionLevel == .nuclear }) {
            nuclearMission = nuclear
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
    @Query private var courses: [ClassroomCourse]

    private var hiddenCourseIds: Set<String> {
        Set(courses.filter { $0.isHidden }.map { $0.courseId })
    }

    private var activeMissions: [Mission] {
        allMissions.filter { mission in
            if mission.status == .completed || mission.status == .abandoned { return false }
            if let courseId = mission.classroomCourseId, hiddenCourseIds.contains(courseId) { return false }
            return true
        }
    }

    @State private var selectedMission: Mission?

    var body: some View {
        ZStack {
            CommandColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FOCUS")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(CommandColors.textPrimary)
                            .tracking(3)
                        Text("Select a mission to start a focus session")
                            .font(CommandTypography.caption)
                            .foregroundStyle(CommandColors.textTertiary)
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
                        ForEach(activeMissions.sorted { $0.urgencyScore > $1.urgencyScore }, id: \.id) { mission in
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
