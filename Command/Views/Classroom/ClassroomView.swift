import SwiftUI
import SwiftData

struct ClassroomView: View {
    @Environment(\.modelContext) private var context
    @Query private var courses: [ClassroomCourse]
    @Query(filter: #Predicate<Mission> { $0.source == .googleClassroom }) private var classroomMissions: [Mission]
    @State private var viewModel = ClassroomViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
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
                    .padding(.horizontal)

                    // Course list
                    CourseListView(courses: courses, missions: classroomMissions)
                        .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .background(CommandColors.background)
            .navigationTitle("Classroom")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .refreshable {
                await viewModel.sync(context: context)
            }
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
