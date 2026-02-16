import SwiftUI
import SwiftData

struct MissionListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Mission.createdAt, order: .reverse) private var allMissions: [Mission]
    @State private var selectedCategory: MissionCategory?
    @State private var searchText = ""
    @State private var selectedMission: Mission?
    @State private var showCreateMission = false

    private var filteredMissions: [Mission] {
        var result = allMissions.filter { $0.status != .completed && $0.status != .abandoned }

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }

        return result
    }

    private var completedMissions: [Mission] {
        allMissions.filter { $0.status == .completed }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category filter
                categoryFilter
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                // Mission list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredMissions, id: \.id) { mission in
                            MissionCard(mission: mission) {
                                selectedMission = mission
                            }
                            .contextMenu {
                                Button {
                                    withAnimation {
                                        mission.status = .completed
                                        mission.completedAt = Date()
                                    }
                                } label: {
                                    Label("Complete", systemImage: "checkmark.circle")
                                }

                                Button {
                                    withAnimation {
                                        mission.status = .abandoned
                                    }
                                } label: {
                                    Label("Abandon", systemImage: "xmark.circle")
                                }

                                Divider()

                                Button(role: .destructive) {
                                    withAnimation {
                                        context.delete(mission)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }

                        if !completedMissions.isEmpty {
                            DisclosureGroup {
                                ForEach(completedMissions, id: \.id) { mission in
                                    MissionCard(mission: mission) {
                                        selectedMission = mission
                                    }
                                    .opacity(0.6)
                                }
                            } label: {
                                Text("Completed (\(completedMissions.count))")
                                    .font(CommandTypography.caption)
                                    .foregroundStyle(CommandColors.textTertiary)
                            }
                            .tint(CommandColors.textTertiary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .background(CommandColors.background)
            .navigationTitle("Missions")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search missions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateMission = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(CommandColors.school)
                    }
                }
            }
            .sheet(item: $selectedMission) { mission in
                MissionDetailView(mission: mission)
            }
            .sheet(isPresented: $showCreateMission) {
                CreateMissionView()
            }
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
