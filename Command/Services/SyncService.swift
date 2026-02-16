import Foundation
import SwiftData
import BackgroundTasks

@MainActor final class SyncService {
    private let classroomService: ClassroomService
    private static let bgTaskId = "com.jgbocobo.command.classroom-sync"

    init(classroomService: ClassroomService) {
        self.classroomService = classroomService
    }

    func syncClassroom(context: ModelContext) async throws {
        guard await classroomService.isAuthenticated else { return }

        let courses = try await classroomService.fetchCourses()

        for courseDTO in courses {
            // Upsert course
            let courseDTOId = courseDTO.id
            let courseDescriptor = FetchDescriptor<ClassroomCourse>(
                predicate: #Predicate { $0.courseId == courseDTOId }
            )
            let course: ClassroomCourse
            if let existing = try? context.fetch(courseDescriptor).first {
                existing.name = courseDTO.name
                existing.section = courseDTO.section
                existing.lastSyncedAt = Date()
                course = existing
            } else {
                course = ClassroomCourse(courseId: courseDTO.id, name: courseDTO.name)
                course.section = courseDTO.section
                context.insert(course)
            }
            // Skip hidden courses — don't sync their assignments
            if course.isHidden {
                continue
            }

            // Fetch coursework
            let courseWork = try await classroomService.fetchCourseWork(courseId: courseDTO.id)

            for work in courseWork {
                let workId: String? = work.id
                let missionDescriptor = FetchDescriptor<Mission>(
                    predicate: #Predicate { $0.classroomAssignmentId == workId }
                )

                if let existing = try? context.fetch(missionDescriptor).first {
                    // Update deadline if changed
                    if let newDeadline = work.deadline {
                        existing.deadline = newDeadline
                    }
                    // Update description only if user hasn't modified it
                    if existing.source == .googleClassroom {
                        existing.missionDescription = work.description ?? ""
                    }
                } else {
                    let mission = Mission(title: work.title, category: .school, source: .googleClassroom)
                    mission.missionDescription = work.description ?? ""
                    mission.classroomCourseId = courseDTO.id
                    mission.classroomAssignmentId = work.id
                    mission.deadline = work.deadline
                    mission.aggressionLevel = .moderate
                    context.insert(mission)
                }

                // Check submission status
                let submissions = try await classroomService.fetchSubmissions(courseId: courseDTO.id, courseWorkId: work.id)
                if let submission = submissions.first, submission.state == "TURNED_IN" || submission.state == "RETURNED" {
                    if let mission = try? context.fetch(missionDescriptor).first, mission.status != .completed {
                        mission.status = .completed
                        mission.completedAt = Date()
                    }
                }
            }
        }

        try context.save()
    }

    static func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: bgTaskId, using: nil) { task in
            guard let bgTask = task as? BGAppRefreshTask else { return }
            // Background sync handled by the app delegate / scene phase
            bgTask.setTaskCompleted(success: true)
        }
    }

    static func scheduleBackgroundSync() {
        let request = BGAppRefreshTaskRequest(identifier: bgTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 2 * 60 * 60) // 2 hours
        try? BGTaskScheduler.shared.submit(request)
    }
}

extension CourseWorkDTO {
    var deadline: Date? {
        guard let dueDate else { return nil }
        var components = DateComponents()
        components.year = dueDate.year
        components.month = dueDate.month
        components.day = dueDate.day
        components.hour = dueTime?.hours ?? 23
        components.minute = dueTime?.minutes ?? 59
        return Calendar.current.date(from: components)
    }
}
