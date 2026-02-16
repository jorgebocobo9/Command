import AppIntents

struct NagShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddMissionIntent(),
            phrases: [
                "Add a mission in \(.applicationName)",
                "Add task to \(.applicationName)",
                "New mission in \(.applicationName)",
                "Create a task in \(.applicationName)",
                "\(.applicationName) add mission",
            ],
            shortTitle: "Add Mission",
            systemImageName: "plus.circle"
        )
    }
}
