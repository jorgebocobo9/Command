import SwiftUI
import SwiftData

struct ClassroomView: View {
    @Environment(\.modelContext) private var context
    @Query private var courses: [ClassroomCourse]
    @Query private var allMissions: [Mission]
    private var classroomMissions: [Mission] {
        allMissions.filter { $0.source == .googleClassroom }
    }
    @State private var viewModel = ClassroomViewModel()
    @State private var showHidden = false

    private var visibleCourses: [ClassroomCourse] {
        showHidden ? courses : courses.filter { !$0.isHidden }
    }

    private var hiddenCount: Int {
        courses.filter { $0.isHidden }.count
    }

    var body: some View {
        ZStack {
            CommandColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CLASSROOM")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(CommandColors.textPrimary)
                            .tracking(3)
                        Text("\(visibleCourses.count) courses synced")
                            .font(CommandTypography.caption)
                            .foregroundStyle(CommandColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)

                    // Connection status
                    if !viewModel.isConnected {
                        connectCard
                    }

                    // Sync status
                    SyncStatusView(
                        lastSynced: viewModel.lastSynced,
                        isSyncing: viewModel.isSyncing,
                        onSync: {
                            Task { await viewModel.sync(context: context) }
                        }
                    )
                    .padding(.horizontal, 16)

                    // Hidden courses toggle
                    if hiddenCount > 0 {
                        Button {
                            withAnimation(CommandAnimations.spring) {
                                showHidden.toggle()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: showHidden ? "eye" : "eye.slash")
                                    .font(.system(size: 12))
                                Text(showHidden ? "Showing all courses" : "\(hiddenCount) hidden")
                                    .font(CommandTypography.caption)
                            }
                            .foregroundStyle(CommandColors.textTertiary)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal, 16)
                    }

                    // Course list
                    CourseListView(courses: visibleCourses, missions: classroomMissions, context: context)
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, 20)
            }
            .scrollContentBackground(.hidden)
        }
        .refreshable {
            await viewModel.sync(context: context)
        }
    }

    private var connectCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "link.badge.plus")
                .font(.system(size: 28))
                .foregroundStyle(CommandColors.school)

            Text("Connect Google Classroom")
                .font(CommandTypography.headline)
                .foregroundStyle(CommandColors.textPrimary)

            Text("Import your courses and assignments automatically.")
                .font(CommandTypography.caption)
                .foregroundStyle(CommandColors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await viewModel.connect() }
            } label: {
                Text("Connect")
                    .font(CommandTypography.headline)
                    .foregroundStyle(CommandColors.textPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(CommandColors.school.opacity(0.2))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(CommandColors.school.opacity(0.4), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(CommandColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}
