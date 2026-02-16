import SwiftUI

struct AggressionConfigView: View {
    let level: AggressionLevel
    @Environment(\.dismiss) private var dismiss

    @State private var config: AggressionLevelConfig
    @State private var showResetConfirm = false

    private let startTimeOptions: [(Int, String)] = [
        (15, "15 min"),
        (30, "30 min"),
        (60, "1 hour"),
        (120, "2 hours"),
        (180, "3 hours"),
        (360, "6 hours"),
        (720, "12 hours"),
        (1440, "1 day"),
        (2880, "2 days"),
        (4320, "3 days"),
        (7200, "5 days"),
        (10080, "1 week"),
    ]

    private let overdueIntervalOptions: [(Int, String)] = [
        (5, "5 min"),
        (10, "10 min"),
        (15, "15 min"),
        (20, "20 min"),
        (30, "30 min"),
        (45, "45 min"),
        (60, "1 hour"),
    ]

    init(level: AggressionLevel) {
        self.level = level
        self._config = State(initialValue: AggressionConfigStore.config(for: level))
    }

    private var color: Color {
        switch level {
        case .gentle: return CommandColors.success
        case .moderate: return CommandColors.warning
        case .aggressive: return CommandColors.urgent
        case .nuclear: return CommandColors.urgent
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Level header
                VStack(spacing: 8) {
                    AggressionBadge(level: level)
                        .scaleEffect(1.5)
                    Text(level.rawValue.uppercased())
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(color)
                        .tracking(3)
                }
                .padding(.top, 8)

                // Notification count
                configSection("REMINDERS BEFORE DEADLINE") {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Number of notifications")
                                .font(CommandTypography.body)
                                .foregroundStyle(CommandColors.textPrimary)
                            Spacer()
                            HStack(spacing: 0) {
                                Button {
                                    if config.notificationCount > 1 {
                                        Haptic.selection()
                                        config.notificationCount -= 1
                                    }
                                } label: {
                                    Image(systemName: "minus")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(config.notificationCount > 1 ? color : CommandColors.textTertiary)
                                        .frame(width: 36, height: 36)
                                        .background(CommandColors.surfaceElevated)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)

                                Text("\(config.notificationCount)")
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundStyle(color)
                                    .frame(width: 48)

                                Button {
                                    if config.notificationCount < 20 {
                                        Haptic.selection()
                                        config.notificationCount += 1
                                    }
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(config.notificationCount < 20 ? color : CommandColors.textTertiary)
                                        .frame(width: 36, height: 36)
                                        .background(CommandColors.surfaceElevated)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }

                // First reminder timing
                configSection("FIRST REMINDER") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How early before the deadline")
                            .font(.system(size: 11))
                            .foregroundStyle(CommandColors.textTertiary)
                            .padding(.horizontal, 16)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(startTimeOptions, id: \.0) { minutes, label in
                                    Button {
                                        Haptic.selection()
                                        withAnimation(CommandAnimations.springQuick) {
                                            config.firstReminderMinutes = minutes
                                        }
                                    } label: {
                                        Text(label)
                                            .font(.system(size: 12, weight: config.firstReminderMinutes == minutes ? .bold : .medium))
                                            .foregroundStyle(config.firstReminderMinutes == minutes ? CommandColors.textPrimary : CommandColors.textSecondary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(config.firstReminderMinutes == minutes ? color.opacity(0.2) : CommandColors.surfaceElevated)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule()
                                                    .stroke(config.firstReminderMinutes == minutes ? color.opacity(0.5) : Color.clear, lineWidth: 0.5)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 12)
                    }
                }

                // Nuclear overdue settings
                if level == .nuclear {
                    configSection("OVERDUE REMINDERS") {
                        VStack(spacing: 12) {
                            // Overdue count
                            HStack {
                                Text("Overdue notifications")
                                    .font(CommandTypography.body)
                                    .foregroundStyle(CommandColors.textPrimary)
                                Spacer()
                                HStack(spacing: 0) {
                                    Button {
                                        if config.overdueCount > 0 {
                                            Haptic.selection()
                                            config.overdueCount -= 1
                                        }
                                    } label: {
                                        Image(systemName: "minus")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(config.overdueCount > 0 ? color : CommandColors.textTertiary)
                                            .frame(width: 36, height: 36)
                                            .background(CommandColors.surfaceElevated)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)

                                    Text("\(config.overdueCount)")
                                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                                        .foregroundStyle(color)
                                        .frame(width: 48)

                                    Button {
                                        if config.overdueCount < 30 {
                                            Haptic.selection()
                                            config.overdueCount += 1
                                        }
                                    } label: {
                                        Image(systemName: "plus")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(config.overdueCount < 30 ? color : CommandColors.textTertiary)
                                            .frame(width: 36, height: 36)
                                            .background(CommandColors.surfaceElevated)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)

                            // Overdue interval
                            if config.overdueCount > 0 {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Repeat every")
                                        .font(.system(size: 11))
                                        .foregroundStyle(CommandColors.textTertiary)
                                        .padding(.horizontal, 16)

                                    HStack(spacing: 8) {
                                        ForEach(overdueIntervalOptions, id: \.0) { minutes, label in
                                            Button {
                                                Haptic.selection()
                                                withAnimation(CommandAnimations.springQuick) {
                                                    config.overdueIntervalMinutes = minutes
                                                }
                                            } label: {
                                                Text(label)
                                                    .font(.system(size: 12, weight: config.overdueIntervalMinutes == minutes ? .bold : .medium))
                                                    .foregroundStyle(config.overdueIntervalMinutes == minutes ? CommandColors.textPrimary : CommandColors.textSecondary)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 8)
                                                    .background(config.overdueIntervalMinutes == minutes ? color.opacity(0.2) : CommandColors.surfaceElevated)
                                                    .clipShape(Capsule())
                                                    .overlay(
                                                        Capsule()
                                                            .stroke(config.overdueIntervalMinutes == minutes ? color.opacity(0.5) : Color.clear, lineWidth: 0.5)
                                                    )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }

                            Spacer().frame(height: 4)
                        }
                    }
                }

                // Preview
                configSection("PREVIEW") {
                    VStack(alignment: .leading, spacing: 6) {
                        let preview = previewSchedule()
                        if preview.isEmpty {
                            Text("No notifications with current settings")
                                .font(.system(size: 12))
                                .foregroundStyle(CommandColors.textTertiary)
                                .padding(16)
                        } else {
                            ForEach(Array(preview.enumerated()), id: \.offset) { _, item in
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(item.isUrgent ? CommandColors.urgent : color.opacity(0.6))
                                        .frame(width: 6, height: 6)
                                    Text(item.label)
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundStyle(CommandColors.textSecondary)
                                    Spacer()
                                    Text(item.timing)
                                        .font(.system(size: 11))
                                        .foregroundStyle(CommandColors.textTertiary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 4)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }

                // Reset
                Button {
                    showResetConfirm = true
                } label: {
                    Text("Reset to defaults")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(CommandColors.textTertiary)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 32)
            }
            .padding(.top, 8)
        }
        .background(CommandColors.background)
        .navigationTitle(level.rawValue.capitalized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onChange(of: config) {
            AggressionConfigStore.save(config, for: level)
        }
        .alert("Reset to defaults?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                AggressionConfigStore.resetToDefaults(for: level)
                config = AggressionLevelConfig.defaultConfig(for: level)
                Haptic.notification(.success)
            }
        }
    }

    // MARK: - Components

    private func configSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
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

    // MARK: - Preview

    private struct PreviewItem {
        let label: String
        let timing: String
        let isUrgent: Bool
    }

    private func previewSchedule() -> [PreviewItem] {
        var items: [PreviewItem] = []
        let count = max(1, config.notificationCount)
        let totalMinutes = config.firstReminderMinutes

        for i in 0..<count {
            let fraction = count == 1 ? 1.0 : Double(i) / Double(count - 1)
            let minutesBefore = Int(Double(totalMinutes) * (1.0 - fraction))
            items.append(PreviewItem(
                label: "Notification \(i + 1)",
                timing: minutesBefore == 0 ? "At deadline" : "\(formatMinutesBrief(minutesBefore)) before",
                isUrgent: fraction > 0.6
            ))
        }

        if level == .nuclear && config.overdueCount > 0 {
            for i in 1...min(config.overdueCount, 5) {
                let mins = i * config.overdueIntervalMinutes
                items.append(PreviewItem(
                    label: "Overdue \(i)",
                    timing: "+\(formatMinutesBrief(mins)) after",
                    isUrgent: true
                ))
            }
            if config.overdueCount > 5 {
                items.append(PreviewItem(
                    label: "... +\(config.overdueCount - 5) more",
                    timing: "",
                    isUrgent: true
                ))
            }
        }

        return items
    }

    private func formatMinutesBrief(_ minutes: Int) -> String {
        if minutes >= 1440 {
            let days = minutes / 1440
            let rem = (minutes % 1440) / 60
            return rem > 0 ? "\(days)d \(rem)h" : "\(days)d"
        } else if minutes >= 60 {
            let hours = minutes / 60
            let rem = minutes % 60
            return rem > 0 ? "\(hours)h \(rem)m" : "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}
