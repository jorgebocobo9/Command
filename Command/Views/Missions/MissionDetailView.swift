import SwiftUI
import SwiftData

struct MissionDetailView: View {
    @Bindable var mission: Mission
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection

                    // Deadline
                    if let deadline = mission.deadline {
                        deadlineSection(deadline)
                    }

                    // Aggression picker
                    aggressionSection

                    // Steps
                    stepsSection

                    // Resources
                    if !mission.resources.isEmpty {
                        resourcesSection
                    }

                    // Metadata
                    metadataSection
                }
                .padding()
            }
            .background(CommandColors.background)
            .navigationTitle("Mission Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(CommandColors.school)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(CommandColors.categoryColor(mission.category))
                    .frame(width: 4, height: 28)

                Text(mission.title)
                    .font(CommandTypography.title)
                    .foregroundStyle(CommandColors.textPrimary)
            }

            if !mission.missionDescription.isEmpty {
                Text(mission.missionDescription)
                    .font(CommandTypography.body)
                    .foregroundStyle(CommandColors.textSecondary)
            }

            HStack(spacing: 12) {
                Label(mission.category.rawValue.capitalized, systemImage: categoryIcon)
                    .font(CommandTypography.caption)
                    .foregroundStyle(CommandColors.categoryColor(mission.category))

                Label(mission.status.rawValue.capitalized, systemImage: "circle.fill")
                    .font(CommandTypography.caption)
                    .foregroundStyle(CommandColors.textSecondary)

                if let load = mission.cognitiveLoad {
                    Label(load.rawValue.capitalized, systemImage: "brain")
                        .font(CommandTypography.caption)
                        .foregroundStyle(CommandColors.textSecondary)
                }
            }
        }
    }

    private var categoryIcon: String {
        switch mission.category {
        case .school: return "graduationcap"
        case .work: return "briefcase"
        case .personal: return "person"
        }
    }

    // MARK: - Deadline

    private func deadlineSection(_ deadline: Date) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("DEADLINE")
                    .font(CommandTypography.caption)
                    .foregroundStyle(CommandColors.textTertiary)
                    .tracking(1.5)

                Text(deadline, format: .dateTime.month().day().hour().minute())
                    .font(CommandTypography.headline)
                    .foregroundStyle(CommandColors.textPrimary)
            }

            Spacer()

            AnimatedCountdown(targetDate: deadline)
        }
        .padding(12)
        .background(CommandColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(mission.isOverdue ? CommandColors.urgent.opacity(0.3) : CommandColors.surfaceBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Aggression

    private var aggressionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AGGRESSION LEVEL")
                .font(CommandTypography.caption)
                .foregroundStyle(CommandColors.textTertiary)
                .tracking(1.5)

            HStack(spacing: 8) {
                ForEach(AggressionLevel.allCases, id: \.self) { level in
                    Button {
                        withAnimation(CommandAnimations.springQuick) {
                            mission.aggressionLevel = level
                        }
                    } label: {
                        VStack(spacing: 4) {
                            AggressionBadge(level: level)
                            Text(level.rawValue.capitalized)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(mission.aggressionLevel == level ? CommandColors.textPrimary : CommandColors.textTertiary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(mission.aggressionLevel == level ? CommandColors.surfaceElevated : CommandColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(mission.aggressionLevel == level ? aggressionColor(level).opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func aggressionColor(_ level: AggressionLevel) -> Color {
        switch level {
        case .gentle: return CommandColors.success
        case .moderate: return CommandColors.warning
        case .aggressive: return CommandColors.urgent
        case .nuclear: return CommandColors.urgent
        }
    }

    // MARK: - Steps

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("STEPS")
                    .font(CommandTypography.caption)
                    .foregroundStyle(CommandColors.textTertiary)
                    .tracking(1.5)

                Spacer()

                if !mission.steps.isEmpty {
                    Text("\(mission.steps.filter(\.isCompleted).count)/\(mission.steps.count)")
                        .font(CommandTypography.caption)
                        .foregroundStyle(CommandColors.textSecondary)
                }
            }

            if mission.steps.isEmpty {
                Text("No steps yet. Create the mission to auto-decompose with AI.")
                    .font(CommandTypography.body)
                    .foregroundStyle(CommandColors.textTertiary)
                    .padding(.vertical, 12)
            } else {
                ForEach(mission.steps.sorted(by: { $0.orderIndex < $1.orderIndex })) { step in
                    MissionStepRow(step: step, accentColor: CommandColors.categoryColor(mission.category))
                }
            }

            // Step progress bar
            if !mission.steps.isEmpty {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(CommandColors.surfaceBorder)
                            .frame(height: 3)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(CommandColors.categoryColor(mission.category))
                            .frame(width: geo.size.width * mission.stepProgress, height: 3)
                            .glow(CommandColors.categoryColor(mission.category), radius: 4, intensity: 0.5)
                    }
                }
                .frame(height: 3)
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Resources

    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("RESOURCES")
                .font(CommandTypography.caption)
                .foregroundStyle(CommandColors.textTertiary)
                .tracking(1.5)

            ForEach(mission.resources) { resource in
                if let url = resource.url {
                    Link(destination: url) {
                        HStack(spacing: 8) {
                            Image(systemName: resourceIcon(resource.type))
                                .font(.system(size: 14))
                                .foregroundStyle(CommandColors.school)

                            Text(resource.title)
                                .font(CommandTypography.body)
                                .foregroundStyle(CommandColors.textPrimary)
                                .lineLimit(1)

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10))
                                .foregroundStyle(CommandColors.textTertiary)
                        }
                        .padding(10)
                        .background(CommandColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }

    private func resourceIcon(_ type: ResourceType) -> String {
        switch type {
        case .video: return "play.rectangle"
        case .article: return "doc.text"
        case .documentation: return "book"
        case .tool: return "wrench"
        }
    }

    // MARK: - Metadata

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DETAILS")
                .font(CommandTypography.caption)
                .foregroundStyle(CommandColors.textTertiary)
                .tracking(1.5)

            VStack(spacing: 0) {
                if let estimated = mission.estimatedMinutes {
                    metadataRow("Estimated", value: "\(estimated) min")
                }

                if mission.totalActualMinutes > 0 {
                    metadataRow("Actual", value: "\(mission.totalActualMinutes) min")
                }

                metadataRow("Created", value: mission.createdAt.formatted(.dateTime.month().day().year()))

                if mission.source == .googleClassroom {
                    metadataRow("Source", value: "Google Classroom")
                }
            }
            .background(CommandColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func metadataRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(CommandTypography.body)
                .foregroundStyle(CommandColors.textSecondary)
            Spacer()
            Text(value)
                .font(CommandTypography.body)
                .foregroundStyle(CommandColors.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
