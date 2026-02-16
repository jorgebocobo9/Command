import SwiftUI
import SwiftData

struct MissionDetailView: View {
    @Bindable var mission: Mission
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var newStepTitle = ""
    @State private var showAddStep = false
    @State private var stepsExpanded = false
    @State private var resourcesExpanded = false
    @State private var viewModel = MissionViewModel()

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

                    // Mark as Done
                    if mission.status != .completed {
                        Button {
                            Haptic.notification(.success)
                            withAnimation(CommandAnimations.spring) {
                                mission.status = .completed
                                mission.completedAt = Date()
                                Task { await NotificationService.shared.cancelNotifications(for: mission.id.uuidString) }
                                try? context.save()
                            }
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                Text("Mark as Done")
                                    .font(CommandTypography.headline)
                            }
                            .foregroundStyle(CommandColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(CommandColors.success.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(CommandColors.success.opacity(0.4), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(CommandColors.success)
                            Text("Completed")
                                .font(CommandTypography.headline)
                                .foregroundStyle(CommandColors.success)
                            if let completedAt = mission.completedAt {
                                Spacer()
                                Text(completedAt, format: .dateTime.month().day())
                                    .font(CommandTypography.caption)
                                    .foregroundStyle(CommandColors.textTertiary)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(CommandColors.success.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
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

    private var sortedSteps: [MissionStep] {
        mission.steps.sorted(by: { $0.orderIndex < $1.orderIndex })
    }

    private var completedCount: Int {
        mission.steps.filter(\.isCompleted).count
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Tappable section header
            Button {
                withAnimation(CommandAnimations.springQuick) { stepsExpanded.toggle() }
            } label: {
                HStack(alignment: .center) {
                    Text("STEPS")
                        .font(CommandTypography.caption)
                        .foregroundStyle(CommandColors.textTertiary)
                        .tracking(1.5)

                    Spacer()

                    if !mission.steps.isEmpty {
                        Text("\(completedCount)/\(mission.steps.count)")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(completedCount == mission.steps.count && !mission.steps.isEmpty
                                ? CommandColors.success
                                : CommandColors.textSecondary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(CommandColors.textTertiary)
                        .rotationEffect(.degrees(stepsExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)
            .padding(.bottom, 10)

            if stepsExpanded {
            // Steps container
            VStack(spacing: 0) {
                if mission.steps.isEmpty && !showAddStep {
                    // Empty state inside card
                    VStack(spacing: 8) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 24))
                            .foregroundStyle(CommandColors.textTertiary.opacity(0.5))
                        Text("No steps yet")
                            .font(CommandTypography.body)
                            .foregroundStyle(CommandColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    ForEach(Array(sortedSteps.enumerated()), id: \.element.id) { index, step in
                        MissionStepRow(
                            step: step,
                            index: index,
                            accentColor: CommandColors.categoryColor(mission.category)
                        )

                        // Divider between steps
                        if index < sortedSteps.count - 1 {
                            Divider()
                                .background(CommandColors.surfaceBorder.opacity(0.5))
                                .padding(.leading, 50)
                        }
                    }
                }

                // Progress bar at bottom of card
                if !mission.steps.isEmpty {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(CommandColors.surfaceBorder.opacity(0.3))

                            Rectangle()
                                .fill(CommandColors.categoryColor(mission.category))
                                .frame(width: geo.size.width * mission.stepProgress)
                        }
                    }
                    .frame(height: 3)
                }
            }
            .background(CommandColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(CommandColors.surfaceBorder, lineWidth: 0.5)
            )

            // Action bar below card
            HStack(spacing: 10) {
                // AI Decompose
                if mission.steps.isEmpty {
                    Button {
                        Task { await viewModel.decomposeMission(mission, context: context) }
                    } label: {
                        HStack(spacing: 5) {
                            if viewModel.isDecomposing {
                                ProgressView()
                                    .tint(CommandColors.categoryColor(mission.category))
                                    .scaleEffect(0.65)
                            } else {
                                Image(systemName: "brain")
                                    .font(.system(size: 11))
                            }
                            Text(viewModel.isDecomposing ? "Generating..." : "AI Steps")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(CommandColors.categoryColor(mission.category))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(CommandColors.categoryColor(mission.category).opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(CommandColors.categoryColor(mission.category).opacity(0.25), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isDecomposing)
                }

                // Add step toggle
                Button {
                    withAnimation(CommandAnimations.springQuick) { showAddStep.toggle() }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: showAddStep ? "xmark" : "plus")
                            .font(.system(size: 10, weight: .bold))
                        Text(showAddStep ? "Cancel" : "Add Step")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(CommandColors.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(CommandColors.surface)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(CommandColors.surfaceBorder, lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.top, 10)

            // Inline add step field
            if showAddStep {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(CommandColors.categoryColor(mission.category))

                    TextField("What's the next step?", text: $newStepTitle)
                        .font(CommandTypography.body)
                        .foregroundStyle(CommandColors.textPrimary)
                        .onSubmit { addStep() }

                    if !newStepTitle.isEmpty {
                        Button { addStep() } label: {
                            Text("Add")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(CommandColors.categoryColor(mission.category))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(CommandColors.categoryColor(mission.category).opacity(0.15))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(CommandColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(CommandColors.categoryColor(mission.category).opacity(0.3), lineWidth: 1)
                )
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            } // end stepsExpanded
        }
    }

    // MARK: - Resources

    private func resourceIconName(_ type: ResourceType) -> String {
        switch type {
        case .video: return "play.rectangle.fill"
        case .article: return "doc.text.fill"
        case .documentation: return "book.fill"
        case .tool: return "wrench.and.screwdriver.fill"
        }
    }

    private func resourceColor(_ type: ResourceType) -> Color {
        switch type {
        case .video: return Color(hex: "FF4444")   // Red for video
        case .article: return CommandColors.school  // Cyan for articles
        case .documentation: return CommandColors.warning // Amber for docs
        case .tool: return CommandColors.success    // Green for tools
        }
    }

    private func resourceTypeLabel(_ type: ResourceType) -> String {
        switch type {
        case .video: return "VIDEO"
        case .article: return "ARTICLE"
        case .documentation: return "DOCS"
        case .tool: return "TOOL"
        }
    }

    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Tappable section header
            Button {
                withAnimation(CommandAnimations.springQuick) { resourcesExpanded.toggle() }
            } label: {
                HStack {
                    Text("RESOURCES")
                        .font(CommandTypography.caption)
                        .foregroundStyle(CommandColors.textTertiary)
                        .tracking(1.5)

                    Spacer()

                    Text("\(mission.resources.count)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(CommandColors.textSecondary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(CommandColors.textTertiary)
                        .rotationEffect(.degrees(resourcesExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)
            .padding(.bottom, 10)

            if resourcesExpanded {
            // Resources container
            VStack(spacing: 0) {
                ForEach(Array(mission.resources.enumerated()), id: \.element.id) { index, resource in
                    if let url = resource.url {
                        Link(destination: url) {
                            HStack(spacing: 10) {
                                // Type icon with colored background
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(resourceColor(resource.type).opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: resourceIconName(resource.type))
                                        .font(.system(size: 13))
                                        .foregroundStyle(resourceColor(resource.type))
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(resource.title)
                                        .font(CommandTypography.body)
                                        .foregroundStyle(CommandColors.textPrimary)
                                        .lineLimit(1)

                                    Text(resourceTypeLabel(resource.type))
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundStyle(resourceColor(resource.type).opacity(0.7))
                                        .tracking(0.5)
                                }

                                Spacer()

                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(CommandColors.textTertiary)
                                    .padding(6)
                                    .background(CommandColors.surfaceElevated)
                                    .clipShape(Circle())
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        }

                        if index < mission.resources.count - 1 {
                            Divider()
                                .background(CommandColors.surfaceBorder.opacity(0.5))
                                .padding(.leading, 54)
                        }
                    }
                }
            }
            .background(CommandColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(CommandColors.surfaceBorder, lineWidth: 0.5)
            )
            } // end resourcesExpanded
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

    private func addStep() {
        guard !newStepTitle.isEmpty else { return }
        Haptic.impact(.light)
        let step = MissionStep(title: newStepTitle, orderIndex: mission.steps.count)
        mission.steps.append(step)
        try? context.save()
        newStepTitle = ""
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
