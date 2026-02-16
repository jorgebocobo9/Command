import Foundation
import SwiftData
import SwiftUI

@Observable @MainActor
final class MissionViewModel {
    var isDecomposing = false
    var decompositionError: String?

    private let aiService: any AIServiceProtocol = OnDeviceAIService()
    private let fallbackService: any AIServiceProtocol = ManualAIService()
    private let classroomService = ClassroomService()
    private let streakService = StreakService()

    func createMission(
        title: String,
        description: String,
        category: MissionCategory,
        priority: MissionPriority,
        aggressionLevel: AggressionLevel,
        deadline: Date?,
        context: ModelContext
    ) -> Mission {
        let mission = Mission(title: title, category: category)
        mission.missionDescription = description
        mission.priority = priority
        mission.aggressionLevel = aggressionLevel
        mission.deadline = deadline
        context.insert(mission)
        try? context.save()

        // Schedule aggression-based notifications
        scheduleNotifications(for: mission)

        return mission
    }

    func completeMission(_ mission: Mission, context: ModelContext) {
        mission.status = .completed
        mission.completedAt = Date()
        try? context.save()

        // Cancel pending notifications for this mission
        Task { await NotificationService.shared.cancelNotifications(for: mission.id.uuidString) }

        // Record streak
        streakService.recordCompletion(category: mission.category, context: context)
    }

    func abandonMission(_ mission: Mission, context: ModelContext) {
        mission.status = .abandoned
        try? context.save()

        // Cancel pending notifications
        Task { await NotificationService.shared.cancelNotifications(for: mission.id.uuidString) }
    }

    func deleteMission(_ mission: Mission, context: ModelContext) {
        let missionId = mission.id.uuidString
        context.delete(mission)
        try? context.save()

        // Cancel pending notifications
        Task { await NotificationService.shared.cancelNotifications(for: missionId) }
    }

    func toggleStep(_ step: MissionStep, context: ModelContext) {
        step.isCompleted.toggle()

        // Update mission status based on step completion
        if let mission = step.mission {
            let allCompleted = mission.steps.allSatisfy(\.isCompleted)
            if allCompleted && !mission.steps.isEmpty {
                mission.status = .completed
                mission.completedAt = Date()

                // Cancel notifications and record streak on auto-complete
                Task { await NotificationService.shared.cancelNotifications(for: mission.id.uuidString) }
                Task { await streakService.recordCompletion(category: mission.category, context: context) }
            } else if mission.status == .completed {
                mission.status = .inProgress
                mission.completedAt = nil

                // Re-schedule notifications if mission uncompleted
                scheduleNotifications(for: mission)
            }
        }

        try? context.save()
    }

    func addStep(to mission: Mission, title: String, context: ModelContext) {
        let step = MissionStep(title: title, orderIndex: mission.steps.count)
        step.mission = mission
        mission.steps.append(step)
        try? context.save()
    }

    func removeStep(_ step: MissionStep, from mission: Mission, context: ModelContext) {
        mission.steps.removeAll { $0.id == step.id }
        context.delete(step)
        // Reindex remaining steps
        for (index, s) in mission.steps.sorted(by: { $0.orderIndex < $1.orderIndex }).enumerated() {
            s.orderIndex = index
        }
        try? context.save()
    }

    // MARK: - AI Decomposition

    func decomposeMission(_ mission: Mission, context: ModelContext) async {
        isDecomposing = true
        decompositionError = nil

        do {
            // Fetch Classroom materials if this is a Classroom mission
            var materials: [MaterialContext] = []
            if mission.source == .googleClassroom,
               let courseId = mission.classroomCourseId,
               let assignmentId = mission.classroomAssignmentId {
                do {
                    let courseWork = try await classroomService.fetchCourseWorkDetail(
                        courseId: courseId, courseWorkId: assignmentId
                    )
                    materials = (courseWork.materials ?? []).compactMap { material -> MaterialContext? in
                        if let video = material.youtubeVideo {
                            return MaterialContext(title: video.title ?? "Video", type: .video, url: video.alternateLink)
                        } else if let drive = material.driveFile?.driveFile {
                            return MaterialContext(title: drive.title ?? "Document", type: .document, url: drive.alternateLink)
                        } else if let link = material.link {
                            return MaterialContext(title: link.title ?? link.url ?? "Link", type: .link, url: link.url)
                        } else if let form = material.form {
                            return MaterialContext(title: form.title ?? "Form", type: .form, url: form.formUrl)
                        }
                        return nil
                    }
                } catch {
                    // Continue without materials if fetch fails
                }
            }

            // Try on-device AI first, fall back to template-based decomposition
            let result: AIDecomposition
            do {
                result = try await aiService.decomposeMission(
                    title: mission.title,
                    description: mission.missionDescription,
                    materials: materials
                )
            } catch {
                result = try await fallbackService.decomposeMission(
                    title: mission.title,
                    description: mission.missionDescription,
                    materials: materials
                )
            }

            // Apply decomposition results
            mission.cognitiveLoad = result.cognitiveLoad
            mission.estimatedMinutes = result.estimatedMinutes

            // Create steps from AI output
            for (index, aiStep) in result.steps.enumerated() {
                let step = MissionStep(title: aiStep.title, orderIndex: index)
                step.estimatedMinutes = aiStep.estimatedMinutes
                step.mission = mission
                mission.steps.append(step)
            }

            // Create resources from Classroom materials
            for material in materials {
                if let url = material.url {
                    let resourceType: ResourceType = material.type == .video ? .video : .article
                    let resource = Resource(title: material.title, urlString: url, type: resourceType)
                    resource.mission = mission
                    mission.resources.append(resource)
                }
            }

            // Create resources from search queries
            for query in result.searchQueries {
                let resource = Resource(
                    title: query.query,
                    urlString: searchURL(query: query.query, platform: query.platform),
                    type: query.platform == .youtube ? .video : .article
                )
                resource.mission = mission
                mission.resources.append(resource)
            }

            mission.status = .inProgress
            try? context.save()
        } catch {
            decompositionError = error.localizedDescription
        }

        isDecomposing = false
    }

    // MARK: - Notifications

    func scheduleNotifications(for mission: Mission) {
        let notifications = AggressionScheduler.scheduleNotifications(for: mission)
        Task {
            // Cancel existing notifications for this mission first
            await NotificationService.shared.cancelNotifications(for: mission.id.uuidString)

            for notification in notifications {
                await NotificationService.shared.scheduleNotification(
                    id: notification.id,
                    title: notification.title,
                    body: notification.body,
                    triggerDate: notification.fireDate,
                    categoryIdentifier: notification.isUrgent ? "URGENT_REMINDER" : "MISSION_REMINDER",
                    userInfo: ["missionId": mission.id.uuidString]
                )
            }
        }
    }

    // MARK: - Helpers

    private func searchURL(query: String, platform: SearchPlatform) -> String {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        switch platform {
        case .youtube: return "https://www.youtube.com/results?search_query=\(encoded)"
        case .google: return "https://www.google.com/search?q=\(encoded)"
        case .googleScholar: return "https://scholar.google.com/scholar?q=\(encoded)"
        }
    }
}
