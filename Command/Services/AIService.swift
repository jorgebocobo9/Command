import Foundation
import FoundationModels

// Protocol for swappable AI backends
protocol AIServiceProtocol {
    func decomposeMission(title: String, description: String) async throws -> AIDecomposition
    func generateMicroStart(for title: String) async throws -> String
}

struct AIDecomposition {
    let steps: [AIStep]
    let estimatedMinutes: Int
    let cognitiveLoad: CognitiveLoad
    let searchQueries: [AISearchQuery]
}

struct AIStep {
    let title: String
    let estimatedMinutes: Int?
}

struct AISearchQuery {
    let query: String
    let platform: SearchPlatform
    let forStepIndex: Int?
}

enum SearchPlatform: String {
    case youtube
    case google
    case googleScholar
}

// Apple Foundation Models implementation
final class OnDeviceAIService: AIServiceProtocol {
    private var session: LanguageModelSession?

    private func getSession() throws -> LanguageModelSession {
        if let session { return session }
        let newSession = LanguageModelSession()
        self.session = newSession
        return newSession
    }

    func decomposeMission(title: String, description: String) async throws -> AIDecomposition {
        guard SystemLanguageModel.default.isAvailable else {
            throw AIServiceError.modelUnavailable
        }

        let session = try getSession()
        let prompt = """
        Break down this task into 3-8 actionable steps. For each step, estimate minutes needed.
        Also estimate total time and cognitive difficulty (light/moderate/heavy/extreme).
        Suggest 2-3 search queries to find helpful resources.

        Task: \(title)
        Details: \(description.isEmpty ? "No additional details" : description)

        Respond in this exact format:
        STEPS:
        1. [step title] | [estimated minutes]
        2. [step title] | [estimated minutes]
        ...
        TOTAL_MINUTES: [number]
        COGNITIVE_LOAD: [light/moderate/heavy/extreme]
        SEARCH:
        - youtube: [query]
        - google: [query]
        - scholar: [query]
        """

        let response = try await session.respond(to: prompt)
        return parseDecomposition(response.content)
    }

    func generateMicroStart(for title: String) async throws -> String {
        guard SystemLanguageModel.default.isAvailable else {
            throw AIServiceError.modelUnavailable
        }

        let session = try getSession()
        let prompt = """
        Generate ONE very small, low-friction first step to start this task.
        It should take under 2 minutes and lower the barrier to starting.
        Be specific to the task. Just the action, nothing else.

        Task: \(title)
        """

        let response = try await session.respond(to: prompt)
        return response.content.trimmingCharacters(in: .whitespacesAndNewlinessAndNewlines)
    }

    private func parseDecomposition(_ text: String) -> AIDecomposition {
        var steps: [AIStep] = []
        var totalMinutes = 30
        var cogLoad = CognitiveLoad.moderate
        var queries: [AISearchQuery] = []

        let lines = text.components(separatedBy: "\n")
        var section = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.starts(with: "STEPS:") { section = "steps"; continue }
            if trimmed.starts(with: "TOTAL_MINUTES:") {
                totalMinutes = Int(trimmed.replacingOccurrences(of: "TOTAL_MINUTES:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)) ?? 30
                continue
            }
            if trimmed.starts(with: "COGNITIVE_LOAD:") {
                let value = trimmed.replacingOccurrences(of: "COGNITIVE_LOAD:", with: "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                cogLoad = CognitiveLoad(rawValue: value) ?? .moderate
                continue
            }
            if trimmed.starts(with: "SEARCH:") { section = "search"; continue }

            if section == "steps" && !trimmed.isEmpty {
                let parts = trimmed.components(separatedBy: "|")
                let title = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: #"^\d+\.\s*"#, with: "", options: String.CompareOptions.regularExpression)
                let minutes = parts.count > 1 ? Int(parts[1].trimmingCharacters(in: .whitespacesAndNewlines)) : nil
                if !title.isEmpty {
                    steps.append(AIStep(title: title, estimatedMinutes: minutes))
                }
            }

            if section == "search" && trimmed.starts(with: "-") {
                let content = trimmed.dropFirst().trimmingCharacters(in: .whitespacesAndNewlines)
                if content.starts(with: "youtube:") {
                    queries.append(AISearchQuery(query: String(content.dropFirst(8)).trimmingCharacters(in: .whitespacesAndNewlines), platform: .youtube, forStepIndex: nil))
                } else if content.starts(with: "scholar:") {
                    queries.append(AISearchQuery(query: String(content.dropFirst(8)).trimmingCharacters(in: .whitespacesAndNewlines), platform: .googleScholar, forStepIndex: nil))
                } else if content.starts(with: "google:") {
                    queries.append(AISearchQuery(query: String(content.dropFirst(7)).trimmingCharacters(in: .whitespacesAndNewlines), platform: .google, forStepIndex: nil))
                }
            }
        }

        if steps.isEmpty {
            steps = [AIStep(title: "Work on: \(text.prefix(50))", estimatedMinutes: totalMinutes)]
        }

        return AIDecomposition(steps: steps, estimatedMinutes: totalMinutes, cognitiveLoad: cogLoad, searchQueries: queries)
    }
}

// Fallback for devices without Apple Intelligence
final class ManualAIService: AIServiceProtocol {
    func decomposeMission(title: String, description: String) async throws -> AIDecomposition {
        throw AIServiceError.modelUnavailable
    }

    func generateMicroStart(for title: String) async throws -> String {
        throw AIServiceError.modelUnavailable
    }
}

enum AIServiceError: Error {
    case modelUnavailable
    case parsingFailed
}
