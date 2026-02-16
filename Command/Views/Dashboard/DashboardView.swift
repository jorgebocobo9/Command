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
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var selectedCategory: MissionCategory?
    @State private var showSettings = false

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

    private var sortedMissions: [Mission] {
        var result = activeMissions

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }

        return result.sorted { $0.urgencyScore > $1.urgencyScore }
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

    private var completedMissions: [Mission] {
        var result = allMissions.filter { mission in
            guard mission.status == .completed else { return false }
            if let courseId = mission.classroomCourseId, hiddenCourseIds.contains(courseId) { return false }
            return true
        }
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        return result
    }

    private var dailyPlan: [Mission] {
        let allActive = activeMissions.sorted { $0.urgencyScore > $1.urgencyScore }
        let overdue = allActive.filter { $0.isOverdue }
        let calendar = Calendar.current
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
        let today = allActive.filter { mission in
            guard let deadline = mission.deadline else { return false }
            return !mission.isOverdue && deadline <= endOfDay
        }
        let urgent = overdue + today
        if urgent.isEmpty {
            return Array(allActive.prefix(3))
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
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    header
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    // Search bar (shown when searching)
                    if isSearching {
                        searchBar
                            .padding(.horizontal, 16)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Category filter
                    if isSearching || !activeMissions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            categoryFilter
                        }
                        .padding(.horizontal, 16)
                    }

                    // Daily Briefing (hide when searching)
                    if !isSearching && !activeMissions.isEmpty {
                        dailyBriefing
                    }

                    // Missions
                    if sortedMissions.isEmpty && completedMissions.isEmpty && !isSearching {
                        EmptyStateView(
                            icon: "checkmark.seal",
                            title: "No missions yet",
                            subtitle: "Create your first mission to get started.",
                            actionLabel: "New Mission",
                            action: { showCreateMission = true }
                        )
                        .padding(.top, 20)
                    } else if sortedMissions.isEmpty && isSearching {
                        VStack(spacing: 8) {
                            Text("No results")
                                .font(CommandTypography.headline)
                                .foregroundStyle(CommandColors.textSecondary)
                            Text("Try a different search or category")
                                .font(CommandTypography.caption)
                                .foregroundStyle(CommandColors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        missionList
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
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            if isSearching {
                // Compact when searching
                Text(greeting)
                    .font(CommandTypography.headline)
                    .foregroundStyle(CommandColors.textPrimary)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(CommandTypography.largeTitle)
                        .foregroundStyle(CommandColors.textPrimary)

                    Text(Date(), format: .dateTime.weekday(.wide).month().day())
                        .font(CommandTypography.caption)
                        .foregroundStyle(CommandColors.textTertiary)
                }
            }

            Spacer()

            HStack(spacing: 10) {
                // Settings
                if !isSearching {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(CommandColors.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(CommandColors.surface)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                // Search toggle
                Button {
                    withAnimation(CommandAnimations.springQuick) {
                        isSearching.toggle()
                        if !isSearching {
                            searchText = ""
                            selectedCategory = nil
                        }
                    }
                } label: {
                    Image(systemName: isSearching ? "xmark" : "magnifyingglass")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(CommandColors.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(CommandColors.surface)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                // Streak badge
                if currentStreak > 0 && !isSearching {
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
        }
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(CommandColors.textTertiary)
            TextField("Search missions...", text: $searchText)
                .font(CommandTypography.body)
                .foregroundStyle(CommandColors.textPrimary)
                .textInputAutocapitalization(.never)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(CommandColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(CommandColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(CommandColors.surfaceBorder, lineWidth: 0.5))
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        HStack(spacing: 8) {
            categoryPill(nil, label: "All")
            ForEach(MissionCategory.allCases, id: \.self) { cat in
                categoryPill(cat, label: cat.rawValue.capitalized)
            }
        }
    }

    private func categoryPill(_ category: MissionCategory?, label: String) -> some View {
        Button {
            Haptic.selection()
            withAnimation(CommandAnimations.springQuick) {
                selectedCategory = selectedCategory == category ? nil : category
            }
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(selectedCategory == category ? CommandColors.textPrimary : CommandColors.textTertiary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedCategory == category ? CommandColors.surfaceElevated : Color.clear)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            selectedCategory == category
                                ? (category.map { CommandColors.categoryColor($0) } ?? CommandColors.textSecondary).opacity(0.5)
                                : CommandColors.surfaceBorder,
                            lineWidth: 0.5
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Daily Briefing

    private var dailyBriefing: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader("YOUR PLAN")
                Spacer()
                Text("\(dailyPlanMinutes)m")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(CommandColors.textTertiary)
            }

            ForEach(Array(dailyPlan.enumerated()), id: \.element.id) { index, mission in
                HStack(spacing: 12) {
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

    // MARK: - Mission List

    private var missionList: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !overdueMissions.isEmpty {
                missionSection("OVERDUE", missions: overdueMissions, color: CommandColors.urgent)
            }

            if !dueTodayMissions.isEmpty {
                missionSection("DUE TODAY", missions: dueTodayMissions, color: CommandColors.warning)
            }

            if !upcomingMissions.isEmpty {
                missionSection("UPCOMING", missions: upcomingMissions, color: CommandColors.textTertiary)
            }

            if overdueMissions.isEmpty && dueTodayMissions.isEmpty && !upcomingMissions.isEmpty && !isSearching {
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

            if !completedMissions.isEmpty {
                completedSection
            }
        }
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
                missionRow(mission)
            }
        }
    }

    private func missionRow(_ mission: Mission) -> some View {
        MissionCard(mission: mission) {
            selectedMission = mission
        }
        .padding(.horizontal, 16)
        .contextMenu {
            Button {
                Haptic.notification(.success)
                mission.status = .completed
                mission.completedAt = Date()
                Task { await NotificationService.shared.cancelNotifications(for: mission.id.uuidString) }
                try? context.save()
            } label: {
                Label("Complete", systemImage: "checkmark.circle")
            }

            Button {
                focusMission = mission
            } label: {
                Label("Focus", systemImage: "scope")
            }

            Divider()

            Button {
                mission.status = .abandoned
                Task { await NotificationService.shared.cancelNotifications(for: mission.id.uuidString) }
                try? context.save()
            } label: {
                Label("Abandon", systemImage: "xmark.circle")
            }

            Button(role: .destructive) {
                Haptic.notification(.warning)
                let missionId = mission.id.uuidString
                Task { await NotificationService.shared.cancelNotifications(for: missionId) }
                context.delete(mission)
                try? context.save()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Completed

    @State private var showCompleted = false

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(CommandAnimations.springQuick) {
                    showCompleted.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Text("COMPLETED")
                        .font(CommandTypography.caption)
                        .foregroundStyle(CommandColors.textTertiary)
                        .tracking(1.5)
                    Text("\(completedMissions.count)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(CommandColors.textTertiary)
                    Spacer()
                    Image(systemName: showCompleted ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(CommandColors.textTertiary)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)

            if showCompleted {
                ForEach(completedMissions, id: \.id) { mission in
                    MissionCard(mission: mission) {
                        selectedMission = mission
                    }
                    .opacity(0.5)
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}
