import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    // Haptics & Notifications
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("notificationSoundEnabled") private var notificationSoundEnabled = true
    @AppStorage("quietHoursEnabled") private var quietHoursEnabled = false
    @AppStorage("quietHoursStart") private var quietHoursStart: Double = 22 // 10 PM
    @AppStorage("quietHoursEnd") private var quietHoursEnd: Double = 7    // 7 AM

    // Defaults
    @AppStorage("defaultAggressionLevel") private var defaultAggression: String = AggressionLevel.moderate.rawValue
    @AppStorage("defaultCategory") private var defaultCategory: String = MissionCategory.school.rawValue

    // Appearance
    @AppStorage("accentColorHex") private var accentColorHex: String = "00D4FF"

    // Reset
    @State private var showResetConfirm = false
    @State private var showDeleteTestData = false

    private var defaultAggressionLevel: Binding<AggressionLevel> {
        Binding(
            get: { AggressionLevel(rawValue: defaultAggression) ?? .moderate },
            set: { defaultAggression = $0.rawValue }
        )
    }

    private let accentOptions: [(String, String)] = [
        ("00D4FF", "Cyan"),
        ("FF2D78", "Magenta"),
        ("00FF88", "Mint"),
        ("FF9500", "Amber"),
        ("BF5AF2", "Purple"),
        ("FF453A", "Red"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Haptics & Feedback
                    settingsSection("FEEDBACK") {
                        toggleRow(
                            icon: "iphone.radiowaves.left.and.right",
                            title: "Vibrations",
                            subtitle: "Haptic feedback on interactions",
                            isOn: $hapticsEnabled
                        )

                        toggleRow(
                            icon: "speaker.wave.2",
                            title: "Notification sounds",
                            subtitle: "Play sound with notifications",
                            isOn: $notificationSoundEnabled
                        )
                    }

                    // MARK: - Quiet Hours
                    settingsSection("QUIET HOURS") {
                        toggleRow(
                            icon: "moon.fill",
                            title: "Quiet hours",
                            subtitle: "Pause notifications during set hours",
                            isOn: $quietHoursEnabled
                        )

                        if quietHoursEnabled {
                            HStack(spacing: 12) {
                                timePickerCompact(label: "From", hour: $quietHoursStart)
                                timePickerCompact(label: "Until", hour: $quietHoursEnd)
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }

                    // MARK: - Default Aggression
                    settingsSection("DEFAULT AGGRESSION") {
                        VStack(spacing: 8) {
                            Text("New missions will use this aggression level")
                                .font(CommandTypography.caption)
                                .foregroundStyle(CommandColors.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)

                            AggressionSlider(level: defaultAggressionLevel)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                        }
                    }

                    // MARK: - Notification Schedule
                    settingsSection("NOTIFICATION SCHEDULE") {
                        ForEach(AggressionLevel.allCases, id: \.self) { level in
                            NavigationLink {
                                AggressionConfigView(level: level)
                            } label: {
                                aggressionRow(level: level)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // MARK: - Default Category
                    settingsSection("DEFAULT CATEGORY") {
                        HStack(spacing: 8) {
                            ForEach(MissionCategory.allCases, id: \.self) { cat in
                                Button {
                                    Haptic.selection()
                                    withAnimation(CommandAnimations.springQuick) {
                                        defaultCategory = cat.rawValue
                                    }
                                } label: {
                                    Text(cat.rawValue.capitalized)
                                        .font(CommandTypography.caption)
                                        .foregroundStyle(defaultCategory == cat.rawValue ? CommandColors.textPrimary : CommandColors.textSecondary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(defaultCategory == cat.rawValue ? CommandColors.surfaceElevated : Color.clear)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(
                                                    defaultCategory == cat.rawValue ? CommandColors.categoryColor(cat).opacity(0.5) : CommandColors.surfaceBorder,
                                                    lineWidth: 0.5
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }

                    // MARK: - Accent Color
                    settingsSection("ACCENT COLOR") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                            ForEach(accentOptions, id: \.0) { hex, name in
                                Button {
                                    Haptic.selection()
                                    withAnimation(CommandAnimations.springQuick) {
                                        accentColorHex = hex
                                    }
                                } label: {
                                    VStack(spacing: 6) {
                                        Circle()
                                            .fill(Color(hex: hex))
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white.opacity(accentColorHex == hex ? 0.8 : 0), lineWidth: 2)
                                            )
                                            .shadow(color: Color(hex: hex).opacity(accentColorHex == hex ? 0.6 : 0), radius: 8)

                                        Text(name)
                                            .font(.system(size: 10, weight: accentColorHex == hex ? .bold : .medium))
                                            .foregroundStyle(accentColorHex == hex ? CommandColors.textPrimary : CommandColors.textTertiary)
                                    }
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(accentColorHex == hex ? CommandColors.surfaceElevated : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }

                    // MARK: - Data
                    settingsSection("DATA") {
                        Button {
                            showDeleteTestData = true
                        } label: {
                            settingsRow(icon: "trash", title: "Delete test data", subtitle: "Remove [TEST] missions", color: CommandColors.warning)
                        }
                        .buttonStyle(.plain)

                        Button {
                            showResetConfirm = true
                        } label: {
                            settingsRow(icon: "exclamationmark.triangle", title: "Reset all data", subtitle: "Delete all missions, sessions, and streaks", color: CommandColors.urgent)
                        }
                        .buttonStyle(.plain)
                    }

                    // Version
                    Text("Nag v1.0")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(CommandColors.textTertiary)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                }
                .padding(.top, 8)
            }
            .background(CommandColors.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color(hex: accentColorHex))
                }
            }
            .alert("Reset all data?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { resetAllData() }
            } message: {
                Text("This will permanently delete all missions, focus sessions, streaks, and energy data. This cannot be undone.")
            }
            .alert("Delete test data?", isPresented: $showDeleteTestData) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { deleteTestData() }
            } message: {
                Text("Remove all missions with [TEST] prefix.")
            }
        }
    }

    // MARK: - Components

    private func settingsSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title)
                .padding(.horizontal, 16)

            VStack(spacing: 0) {
                content()
            }
            .background(CommandColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(CommandColors.surfaceBorder, lineWidth: 0.5)
            )
            .padding(.horizontal, 16)
        }
    }

    private func toggleRow(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: accentColorHex))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(CommandTypography.body)
                    .foregroundStyle(CommandColors.textPrimary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(CommandColors.textTertiary)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color(hex: accentColorHex))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func settingsRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(CommandTypography.body)
                    .foregroundStyle(color)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(CommandColors.textTertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(CommandColors.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func aggressionRow(level: AggressionLevel) -> some View {
        let config = AggressionConfigStore.config(for: level)
        let color = aggressionColor(level)
        return HStack(spacing: 12) {
            AggressionBadge(level: level)

            VStack(alignment: .leading, spacing: 2) {
                Text(level.rawValue.capitalized)
                    .font(CommandTypography.body)
                    .foregroundStyle(CommandColors.textPrimary)
                Text(aggressionSummary(config: config, level: level))
                    .font(.system(size: 11))
                    .foregroundStyle(CommandColors.textTertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(color.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func aggressionColor(_ level: AggressionLevel) -> Color {
        switch level {
        case .gentle: return CommandColors.success
        case .moderate: return CommandColors.warning
        case .aggressive: return CommandColors.urgent
        case .nuclear: return CommandColors.urgent
        }
    }

    private func aggressionSummary(config: AggressionLevelConfig, level: AggressionLevel) -> String {
        let count = config.notificationCount
        let time = formatMinutesBrief(config.firstReminderMinutes)
        var summary = "\(count) reminder\(count == 1 ? "" : "s"), starts \(time) before"
        if level == .nuclear && config.overdueCount > 0 {
            summary += " + every \(config.overdueIntervalMinutes)min overdue"
        }
        return summary
    }

    private func formatMinutesBrief(_ minutes: Int) -> String {
        if minutes >= 1440 {
            let days = minutes / 1440
            return "\(days)d"
        } else if minutes >= 60 {
            let hours = minutes / 60
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    private func timePickerCompact(label: String, hour: Binding<Double>) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(CommandColors.textTertiary)

            Menu {
                ForEach(0..<24, id: \.self) { h in
                    Button {
                        hour.wrappedValue = Double(h)
                    } label: {
                        Text(formatHour(h))
                    }
                }
            } label: {
                Text(formatHour(Int(hour.wrappedValue)))
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundStyle(CommandColors.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(CommandColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func formatHour(_ hour: Int) -> String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let ampm = hour < 12 ? "AM" : "PM"
        return "\(h):00 \(ampm)"
    }

    // MARK: - Actions

    @Query private var allMissions: [Mission]
    @Query private var allSessions: [FocusSession]
    @Query private var allStreaks: [Streak]
    @Query private var allProfiles: [EnergyProfile]

    private func deleteTestData() {
        let testMissions = allMissions.filter { $0.title.hasPrefix("[TEST]") }
        for m in testMissions { context.delete(m) }
        try? context.save()
        Haptic.notification(.success)
    }

    private func resetAllData() {
        for m in allMissions { context.delete(m) }
        for s in allSessions { context.delete(s) }
        for s in allStreaks { context.delete(s) }
        for p in allProfiles { context.delete(p) }
        try? context.save()
        Haptic.notification(.warning)
    }
}
