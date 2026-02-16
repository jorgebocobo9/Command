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
                // DashboardView() — Agent Frontend builds this
                PlaceholderTab(name: "Dashboard")
            }
            Tab("Missions", systemImage: "target", value: 1) {
                // MissionListView() — Agent Frontend builds this
                PlaceholderTab(name: "Missions")
            }
            Tab("Classroom", systemImage: "graduationcap", value: 2) {
                // ClassroomView() — Agent Frontend builds this
                PlaceholderTab(name: "Classroom")
            }
            Tab("Focus", systemImage: "scope", value: 3) {
                // FocusSessionView() — Agent Frontend builds this
                PlaceholderTab(name: "Focus")
            }
            Tab("Intel", systemImage: "chart.bar.xaxis.ascending", value: 4) {
                // IntelView() — Agent Frontend builds this
                PlaceholderTab(name: "Intel")
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct PlaceholderTab: View {
    let name: String

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.06)
                .ignoresSafeArea()
            Text(name)
                .font(.title)
                .foregroundStyle(.white.opacity(0.3))
        }
    }
}
