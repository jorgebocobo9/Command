import SwiftUI
import SwiftData

struct MissionListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Mission.createdAt, order: .reverse) private var allMissions: [Mission]
    @Query private var courses: [ClassroomCourse]
    @State private var selectedCategory: MissionCategory?
    @State private var searchText = ""
    @State private var selectedMission: Mission?
    @State private var showCreateMission = false
    @State private var focusMission: Mission?

    private var hiddenCourseIds: Set<String> {
        Set(courses.filter { $0.isHidden }.map { $0.courseId })
    }

    private var visibleMissions: [Mission] {
        allMissions.filter { mission in
            guard let courseId = mission.classroomCourseId else { return true }
            return !hiddenCourseIds.contains(courseId)
        }
    }

    private var filteredMissions: [Mission] {
        var result = visibleMissions.filter { $0.status != .completed && $0.status != .abandoned }

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }

        return result
    }

    private var completedMissions: [Mission] {
        visibleMissions.filter { $0.status == .completed }
    }

    var body: some View {
        ZStack {
            CommandColors.background.ignoresSafeArea()

            VStack(spacing: 8) {
                // Header
                HStack {
                    Text("MISSIONS")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(CommandColors.textPrimary)
                        .tracking(3)
                    Spacer()
                    Button {
                        Haptic.impact(.medium)
                        showCreateMission = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(CommandColors.school)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)

                // Search
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundStyle(CommandColors.textTertiary)
                    TextField("Search missions", text: $searchText)
                        .font(CommandTypography.body)
                        .foregroundStyle(CommandColors.textPrimary)
                }
                .padding(10)
                .background(CommandColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(CommandColors.surfaceBorder, lineWidth: 0.5))
                .padding(.horizontal, 16)

                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    categoryFilter
                }
                .padding(.horizontal, 16)

                // Mission list
                if filteredMissions.isEmpty && completedMissions.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "target",
                        title: "No missions yet",
                        subtitle: "Create your first mission to start tracking progress.",
                        actionLabel: "Create Mission",
                        action: { showCreateMission = true }
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(filteredMissions, id: \.id) { mission in
                            MissionCard(mission: mission) {
                                selectedMission = mission
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Haptic.notification(.warning)
                                    let missionId = mission.id.uuidString
                                    Task { await NotificationService.shared.cancelNotifications(for: missionId) }
                                    context.delete(mission)
                                    try? context.save()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    mission.status = .abandoned
                                    Task { await NotificationService.shared.cancelNotifications(for: mission.id.uuidString) }
                                    try? context.save()
                                } label: {
                                    Label("Abandon", systemImage: "xmark.circle")
                                }
                                .tint(CommandColors.warning)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    Haptic.notification(.success)
                                    mission.status = .completed
                                    mission.completedAt = Date()
                                    Task { await NotificationService.shared.cancelNotifications(for: mission.id.uuidString) }
                                    try? context.save()
                                } label: {
                                    Label("Complete", systemImage: "checkmark.circle")
                                }
                                .tint(CommandColors.success)

                                Button {
                                    focusMission = mission
                                } label: {
                                    Label("Focus", systemImage: "scope")
                                }
                                .tint(CommandColors.school)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }

                        if !completedMissions.isEmpty {
                            Section {
                                ForEach(completedMissions, id: \.id) { mission in
                                    MissionCard(mission: mission) {
                                        selectedMission = mission
                                    }
                                    .opacity(0.5)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                }
                            } header: {
                                Text("Completed (\(completedMissions.count))")
                                    .font(CommandTypography.caption)
                                    .foregroundStyle(CommandColors.textTertiary)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
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

    private var categoryFilter: some View {
        HStack(spacing: 8) {
            categoryButton(nil, label: "All")
            ForEach(MissionCategory.allCases, id: \.self) { category in
                categoryButton(category, label: category.rawValue.capitalized)
            }
        }
    }

    private func categoryButton(_ category: MissionCategory?, label: String) -> some View {
        Button {
            Haptic.selection()
            withAnimation(CommandAnimations.springQuick) {
                selectedCategory = category
            }
        } label: {
            Text(label)
                .font(CommandTypography.caption)
                .foregroundStyle(selectedCategory == category ? CommandColors.textPrimary : CommandColors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedCategory == category ? CommandColors.surfaceElevated : CommandColors.surface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(selectedCategory == category ? categoryBorderColor(category) : CommandColors.surfaceBorder, lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }

    private func categoryBorderColor(_ category: MissionCategory?) -> Color {
        guard let category else { return CommandColors.textSecondary }
        return CommandColors.categoryColor(category)
    }
}
