import SwiftUI
import SwiftData

struct CourseListView: View {
    let courses: [ClassroomCourse]
    let missions: [Mission]
    let context: ModelContext

    var body: some View {
        if courses.isEmpty {
            EmptyStateView(
                icon: "graduationcap",
                title: "No courses synced",
                subtitle: "Connect Google Classroom and sync to import your courses."
            )
        } else {
            LazyVStack(spacing: 12) {
                ForEach(courses, id: \.courseId) { course in
                    CourseRow(course: course, missions: missionsForCourse(course), context: context)
                }
            }
        }
    }

    private func missionsForCourse(_ course: ClassroomCourse) -> [Mission] {
        missions.filter { $0.classroomCourseId == course.courseId }
    }
}

struct CourseRow: View {
    let course: ClassroomCourse
    let missions: [Mission]
    let context: ModelContext
    @State private var expanded = false

    private var activeMissions: [Mission] {
        missions.filter { $0.status != .completed && $0.status != .abandoned }
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(CommandAnimations.spring) { expanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(CommandColors.school)
                        .frame(width: 4, height: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(course.name)
                            .font(CommandTypography.headline)
                            .foregroundStyle(course.isHidden ? CommandColors.textTertiary : CommandColors.textPrimary)
                            .lineLimit(1)

                        if let section = course.section {
                            Text(section)
                                .font(CommandTypography.caption)
                                .foregroundStyle(CommandColors.textSecondary)
                        }
                    }

                    Spacer()

                    if !activeMissions.isEmpty {
                        Text("\(activeMissions.count)")
                            .font(CommandTypography.mono)
                            .foregroundStyle(CommandColors.school)
                    }

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(CommandColors.textTertiary)
                }
                .padding(12)
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(spacing: 4) {
                    ForEach(missions.sorted(by: { ($0.deadline ?? .distantFuture) < ($1.deadline ?? .distantFuture) }), id: \.id) { mission in
                        HStack(spacing: 8) {
                            Image(systemName: mission.status == .completed ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 14))
                                .foregroundStyle(mission.status == .completed ? CommandColors.success : CommandColors.textTertiary)

                            Text(mission.title)
                                .font(CommandTypography.body)
                                .foregroundStyle(mission.status == .completed ? CommandColors.textTertiary : CommandColors.textPrimary)
                                .lineLimit(1)

                            Spacer()

                            if let deadline = mission.deadline {
                                Text(deadline, format: .dateTime.month(.abbreviated).day())
                                    .font(CommandTypography.caption)
                                    .foregroundStyle(mission.isOverdue ? CommandColors.urgent : CommandColors.textTertiary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                    }

                    // Hide/Show button
                    Button {
                        Haptic.selection()
                        withAnimation(CommandAnimations.spring) {
                            course.isHidden.toggle()
                            // Remove missions from this course when hiding
                            if course.isHidden {
                                for mission in missions where mission.status != .completed {
                                    let missionId = mission.id.uuidString
                                    Task { await NotificationService.shared.cancelNotifications(for: missionId) }
                                    context.delete(mission)
                                }
                            }
                            try? context.save()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: course.isHidden ? "eye" : "eye.slash")
                                .font(.system(size: 11))
                            Text(course.isHidden ? "Unhide Course" : "Hide Course")
                                .font(CommandTypography.caption)
                        }
                        .foregroundStyle(CommandColors.textTertiary)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(CommandColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(course.isHidden ? 0.5 : 1)
    }
}
