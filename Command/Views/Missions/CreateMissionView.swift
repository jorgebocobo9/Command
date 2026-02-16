import SwiftUI
import SwiftData

struct CreateMissionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var category: MissionCategory = .school
    @State private var priority: MissionPriority = .medium
    @State private var aggressionLevel: AggressionLevel = .moderate
    @State private var hasDeadline = false
    @State private var deadline = Date().addingTimeInterval(86400)
    @State private var isDecomposing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TITLE")
                            .font(CommandTypography.caption)
                            .foregroundStyle(CommandColors.textTertiary)
                            .tracking(1.5)

                        TextField("Mission title", text: $title)
                            .font(CommandTypography.headline)
                            .foregroundStyle(CommandColors.textPrimary)
                            .padding(12)
                            .background(CommandColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 6) {
                        Text("DESCRIPTION")
                            .font(CommandTypography.caption)
                            .foregroundStyle(CommandColors.textTertiary)
                            .tracking(1.5)

                        TextField("Details (optional)", text: $description, axis: .vertical)
                            .font(CommandTypography.body)
                            .foregroundStyle(CommandColors.textPrimary)
                            .lineLimit(3...6)
                            .padding(12)
                            .background(CommandColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Category
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CATEGORY")
                            .font(CommandTypography.caption)
                            .foregroundStyle(CommandColors.textTertiary)
                            .tracking(1.5)

                        HStack(spacing: 8) {
                            ForEach(MissionCategory.allCases, id: \.self) { cat in
                                Button {
                                    withAnimation(CommandAnimations.springQuick) { category = cat }
                                } label: {
                                    Text(cat.rawValue.capitalized)
                                        .font(CommandTypography.caption)
                                        .foregroundStyle(category == cat ? CommandColors.textPrimary : CommandColors.textSecondary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(category == cat ? CommandColors.surfaceElevated : CommandColors.surface)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(category == cat ? CommandColors.categoryColor(cat).opacity(0.5) : CommandColors.surfaceBorder, lineWidth: 0.5)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Priority
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PRIORITY")
                            .font(CommandTypography.caption)
                            .foregroundStyle(CommandColors.textTertiary)
                            .tracking(1.5)

                        HStack(spacing: 8) {
                            ForEach(MissionPriority.allCases, id: \.self) { p in
                                Button {
                                    withAnimation(CommandAnimations.springQuick) { priority = p }
                                } label: {
                                    Text(p.rawValue.capitalized)
                                        .font(CommandTypography.caption)
                                        .foregroundStyle(priority == p ? CommandColors.textPrimary : CommandColors.textSecondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(priority == p ? CommandColors.surfaceElevated : CommandColors.surface)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Aggression
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AGGRESSION")
                            .font(CommandTypography.caption)
                            .foregroundStyle(CommandColors.textTertiary)
                            .tracking(1.5)

                        AggressionSlider(level: $aggressionLevel)
                    }

                    // Deadline
                    VStack(alignment: .leading, spacing: 6) {
                        Toggle(isOn: $hasDeadline) {
                            Text("DEADLINE")
                                .font(CommandTypography.caption)
                                .foregroundStyle(CommandColors.textTertiary)
                                .tracking(1.5)
                        }
                        .tint(CommandColors.school)

                        if hasDeadline {
                            DatePicker("", selection: $deadline, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(CommandColors.school)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }

                    // AI Decompose button
                    Button {
                        decomposeMission()
                    } label: {
                        HStack {
                            if isDecomposing {
                                ProgressView()
                                    .tint(CommandColors.textPrimary)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "brain")
                            }
                            Text(isDecomposing ? "Decomposing..." : "AI Decompose")
                                .font(CommandTypography.headline)
                        }
                        .foregroundStyle(CommandColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [CommandColors.categoryColor(category).opacity(0.3), CommandColors.categoryColor(category).opacity(0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(CommandColors.categoryColor(category).opacity(0.3), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(title.isEmpty || isDecomposing)
                    .opacity(title.isEmpty ? 0.5 : 1)
                }
                .padding()
            }
            .background(CommandColors.background)
            .navigationTitle("New Mission")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(CommandColors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") { createMission() }
                        .foregroundStyle(CommandColors.school)
                        .disabled(title.isEmpty)
                }
            }
        }
    }

    @State private var viewModel = MissionViewModel()

    private func createMission() {
        let mission = Mission(title: title, category: category)
        mission.missionDescription = description
        mission.priority = priority
        mission.aggressionLevel = aggressionLevel
        mission.deadline = hasDeadline ? deadline : nil
        context.insert(mission)
        try? context.save()

        // Schedule aggression-based notifications
        viewModel.scheduleNotifications(for: mission)

        Haptic.notification(.success)
        dismiss()
    }

    private func decomposeMission() {
        guard !title.isEmpty else { return }
        isDecomposing = true

        // Create mission first, then decompose with AI
        let mission = Mission(title: title, category: category)
        mission.missionDescription = description
        mission.priority = priority
        mission.aggressionLevel = aggressionLevel
        mission.deadline = hasDeadline ? deadline : nil
        context.insert(mission)
        try? context.save()

        Task {
            await viewModel.decomposeMission(mission, context: context)
            await MainActor.run {
                isDecomposing = false
                // Schedule notifications after decomposition
                viewModel.scheduleNotifications(for: mission)
                dismiss()
            }
        }
    }
}
