import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Query private var allMissions: [Mission]
    @Query private var courses: [ClassroomCourse]
    @Query private var streaks: [Streak]
    @State private var selectedMission: Mission?
    @State private var showCreateMission = false
    @State private var focusMission: Mission?

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

    // Auto-prioritized by urgency score
    private var sortedMissions: [Mission] {
        activeMissions.sorted { $0.urgencyScore > $1.urgencyScore }
    }

    private var overdueMissions: [Mission] {
        sortedMissions.filter { $0.isOverdue }
    }

    private var dueTodayMissions: [Mission] {
        let calendar = Calendar.current
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
        return sortedMissions.filter { mission in
            guard let deadline = mission.deadline else { return false }
            return !mission.isOverdue && deadline <= endOfDay
        }
    }

    private var upcomingMissions: [Mission] {
        let calendar = Calendar.current
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
        return sortedMissions.filter { mission in
            guard let deadline = mission.deadline else { return true }
            return deadline > endOfDay
        }
    }

    // Daily briefing: top missions to tackle today, ordered by urgency
    private var dailyPlan: [Mission] {
        let urgent = overdueMissions + dueTodayMissions
        if urgent.isEmpty {
            // No urgent tasks — suggest top 3 by score
            return Array(sortedMissions.prefix(3))
        }
        return urgent
    }

    private var dailyPlanMinutes: Int {
        dailyPlan.reduce(0) { $0 + ($1.estimatedMinutes ?? 25) }
    }

    private var currentStreak: Int {
        streaks.first(where: { $0.category == .overall })?.currentCount ?? 0
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
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(greeting)
                                .font(CommandTypography.largeTitle)
                                .foregroundStyle(CommandColors.textPrimary)

                            Text(Date(), format: .dateTime.weekday(.wide).month().day())
                                .font(CommandTypography.caption)
                                .foregroundStyle(CommandColors.textTertiary)
                        }

                        Spacer()

                        if currentStreak > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(CommandColors.warning)
                                Text("\(currentStreak)")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundStyle(CommandColors.textPrimary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(CommandColors.warning.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // Quick stats
                    HStack(spacing: 8) {
                        quickStat(
                            count: overdueMissions.count,
                            label: "Overdue",
                            color: CommandColors.urgent
                        )
                        quickStat(
                            count: dueTodayMissions.count,
                            label: "Today",
                            color: CommandColors.warning
                        )
                        quickStat(
                            count: activeMissions.count,
                            label: "Active",
                            color: CommandColors.school
                        )
                    }
                    .padding(.horizontal, 16)

                    // Daily Briefing
                    if !activeMissions.isEmpty {
                        dailyBriefing
                    }

                    // Mission sections
                    if activeMissions.isEmpty {
                        EmptyStateView(
                            icon: "checkmark.seal",
                            title: "No missions yet",
                            subtitle: "Create your first mission to get started.",
                            actionLabel: "New Mission",
                            action: { showCreateMission = true }
                        )
                        .padding(.top, 20)
                    } else {
                        if !overdueMissions.isEmpty {
                            missionSection("OVERDUE", missions: overdueMissions, color: CommandColors.urgent)
                        }

                        if !dueTodayMissions.isEmpty {
                            missionSection("DUE TODAY", missions: dueTodayMissions, color: CommandColors.warning)
                        }

                        if !upcomingMissions.isEmpty {
                            missionSection("UPCOMING", missions: upcomingMissions, color: CommandColors.textTertiary)
                        }

                        if overdueMissions.isEmpty && dueTodayMissions.isEmpty && !upcomingMissions.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 14))
                                    .foregroundStyle(CommandColors.success)
                                Text("Nothing due today")
                                    .font(CommandTypography.caption)
                                    .foregroundStyle(CommandColors.textSecondary)
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.bottom, 100)
            }
            .scrollContentBackground(.hidden)

            // FAB
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
        .fullScreenCover(item: $focusMission) { mission in
            FocusSessionView(mission: mission)
        }
    }

    // MARK: - Daily Briefing

    private var dailyBriefing: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader("YOUR PLAN")
                Spacer()
                Text("\(dailyPlanMinutes)m total")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(CommandColors.textTertiary)
            }

            ForEach(Array(dailyPlan.enumerated()), id: \.element.id) { index, mission in
                HStack(spacing: 12) {
                    // Order number
                    Text("\(index + 1)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(CommandColors.categoryColor(mission.category))
                        .frame(width: 24, height: 24)
                        .background(CommandColors.categoryColor(mission.category).opacity(0.1))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(mission.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(CommandColors.textPrimary)
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            if let mins = mission.estimatedMinutes {
                                Text("\(mins)m")
                                    .font(.system(size: 11))
                                    .foregroundStyle(CommandColors.textTertiary)
                            }
                            if mission.isOverdue {
                                Text("OVERDUE")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(CommandColors.urgent)
                            } else if let deadline = mission.deadline {
                                Text(deadline, style: .relative)
                                    .font(.system(size: 11))
                                    .foregroundStyle(CommandColors.textTertiary)
                            }
                        }
                    }

                    Spacer()

                    // Quick focus button
                    Button {
                        Haptic.impact(.light)
                        focusMission = mission
                    } label: {
                        Image(systemName: "scope")
                            .font(.system(size: 14))
                            .foregroundStyle(CommandColors.categoryColor(mission.category))
                            .frame(width: 32, height: 32)
                            .background(CommandColors.categoryColor(mission.category).opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedMission = mission
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [CommandColors.school.opacity(0.04), CommandColors.surface],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(CommandColors.school.opacity(0.15), lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Components

    private func quickStat(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundStyle(count > 0 ? color : CommandColors.textTertiary)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(CommandColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(count > 0 ? color.opacity(0.06) : CommandColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(count > 0 ? color.opacity(0.2) : CommandColors.surfaceBorder, lineWidth: 0.5)
        )
    }

    private func missionSection(_ title: String, missions: [Mission], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                if color == CommandColors.urgent {
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                }
                Text(title)
                    .font(CommandTypography.caption)
                    .foregroundStyle(color)
                    .tracking(1.5)
            }
            .padding(.horizontal, 16)

            ForEach(missions, id: \.id) { mission in
                MissionCard(mission: mission) {
                    selectedMission = mission
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
