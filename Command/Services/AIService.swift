import Foundation
import FoundationModels

// Protocol for swappable AI backends
protocol AIServiceProtocol: Sendable {
    func decomposeMission(title: String, description: String, materials: [MaterialContext]) async throws -> AIDecomposition
    func generateMicroStart(for title: String) async throws -> String
}

// Lightweight struct summarizing Classroom materials for AI context
struct MaterialContext: Sendable {
    let title: String
    let type: MaterialType
    let url: String?

    enum MaterialType: String, Sendable {
        case video, document, link, form
    }
}

extension AIServiceProtocol {
    // Default overload without materials for backward compatibility
    func decomposeMission(title: String, description: String) async throws -> AIDecomposition {
        try await decomposeMission(title: title, description: description, materials: [])
    }
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
final class OnDeviceAIService: AIServiceProtocol, @unchecked Sendable {
    private var session: LanguageModelSession?

    private func getSession() throws -> LanguageModelSession {
        if let session { return session }
        let newSession = LanguageModelSession()
        self.session = newSession
        return newSession
    }

    func decomposeMission(title: String, description: String, materials: [MaterialContext]) async throws -> AIDecomposition {
        guard SystemLanguageModel.default.isAvailable else {
            throw AIServiceError.modelUnavailable
        }

        let materialsText = materials.isEmpty ? "None" : materials.enumerated().map { i, m in
            "  \(i + 1). [\(m.type.rawValue)] \(m.title)\(m.url != nil ? " (\(m.url!))" : "")"
        }.joined(separator: "\n")

        let session = try getSession()
        let prompt = """
        Break down this task into 3-8 actionable steps. For each step, estimate minutes needed.
        Also estimate total time and cognitive difficulty (light/moderate/heavy/extreme).
        Suggest 2-3 search queries to find helpful resources.
        If materials are provided, include steps to review/complete them.

        Task: \(title)
        Details: \(description.isEmpty ? "No additional details" : description)
        Materials:
        \(materialsText)

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
        return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
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

// Fallback for devices without Apple Intelligence — generates template-based steps
final class ManualAIService: AIServiceProtocol {
    func decomposeMission(title: String, description: String, materials: [MaterialContext]) async throws -> AIDecomposition {
        let lower = title.lowercased()
        let desc = description.lowercased()
        let combined = lower + " " + desc

        // Build material-based steps first
        var materialSteps: [AIStep] = []
        var materialResources: [AISearchQuery] = []

        for material in materials {
            switch material.type {
            case .video:
                materialSteps.append(AIStep(title: "Watch: \(material.title)", estimatedMinutes: 15))
                if let url = material.url {
                    materialResources.append(AISearchQuery(query: material.title, platform: .youtube, forStepIndex: materialSteps.count - 1))
                }
            case .document:
                materialSteps.append(AIStep(title: "Read: \(material.title)", estimatedMinutes: 20))
            case .link:
                materialSteps.append(AIStep(title: "Review: \(material.title)", estimatedMinutes: 10))
            case .form:
                materialSteps.append(AIStep(title: "Complete form: \(material.title)", estimatedMinutes: 15))
            }
        }

        // Get base template decomposition
        var base: AIDecomposition
        if combined.contains("essay") || combined.contains("paper") || combined.contains("write") || combined.contains("report") {
            base = writingDecomposition(title)
        } else if combined.contains("quiz") || combined.contains("exam") || combined.contains("test") || combined.contains("review") {
            base = studyDecomposition(title)
        } else if combined.contains("code") || combined.contains("program") || combined.contains("develop") || combined.contains("build") || combined.contains("implement") {
            base = codingDecomposition(title)
        } else if combined.contains("read") || combined.contains("chapter") || combined.contains("module") {
            base = readingDecomposition(title)
        } else if combined.contains("present") || combined.contains("slide") || combined.contains("pitch") {
            base = presentationDecomposition(title)
        } else if combined.contains("exercise") || combined.contains("problem") || combined.contains("worksheet") || combined.contains("assessment") {
            base = exerciseDecomposition(title)
        } else {
            base = genericDecomposition(title)
        }

        // If we have material steps, insert them after the first "understand" step
        if !materialSteps.isEmpty {
            var allSteps = [base.steps[0]] // Keep "understand requirements" first
            allSteps.append(contentsOf: materialSteps)
            allSteps.append(contentsOf: base.steps.dropFirst()) // Then the rest
            let materialMinutes = materialSteps.reduce(0) { $0 + ($1.estimatedMinutes ?? 10) }
            return AIDecomposition(
                steps: allSteps,
                estimatedMinutes: base.estimatedMinutes + materialMinutes,
                cognitiveLoad: base.cognitiveLoad,
                searchQueries: base.searchQueries + materialResources
            )
        }

        return base
    }

    func generateMicroStart(for title: String) async throws -> String {
        let starters = [
            "Open the assignment instructions and read the first paragraph.",
            "Create a new blank document and write just the title.",
            "Spend 60 seconds listing what you already know about this topic.",
            "Find and bookmark one reference you'll need.",
            "Write down the three most important requirements.",
            "Set up your workspace — close distractions, open tools.",
            "Outline just the first section in 3 bullet points."
        ]
        return starters.randomElement()!
    }

    // MARK: - Templates

    private func writingDecomposition(_ title: String) -> AIDecomposition {
        AIDecomposition(
            steps: [
                AIStep(title: "Read and understand the prompt/requirements", estimatedMinutes: 10),
                AIStep(title: "Research and gather sources", estimatedMinutes: 20),
                AIStep(title: "Create an outline with main arguments", estimatedMinutes: 15),
                AIStep(title: "Write the introduction", estimatedMinutes: 15),
                AIStep(title: "Write body paragraphs", estimatedMinutes: 40),
                AIStep(title: "Write the conclusion", estimatedMinutes: 10),
                AIStep(title: "Proofread, revise, and format", estimatedMinutes: 15),
            ],
            estimatedMinutes: 125,
            cognitiveLoad: .heavy,
            searchQueries: [
                AISearchQuery(query: "\(title) examples", platform: .google, forStepIndex: 1),
                AISearchQuery(query: "\(title) guide", platform: .youtube, forStepIndex: 2),
            ]
        )
    }

    private func studyDecomposition(_ title: String) -> AIDecomposition {
        AIDecomposition(
            steps: [
                AIStep(title: "Gather notes and study materials", estimatedMinutes: 10),
                AIStep(title: "Review key concepts and definitions", estimatedMinutes: 20),
                AIStep(title: "Summarize each topic in your own words", estimatedMinutes: 25),
                AIStep(title: "Practice with sample questions", estimatedMinutes: 20),
                AIStep(title: "Review weak areas and re-study", estimatedMinutes: 15),
            ],
            estimatedMinutes: 90,
            cognitiveLoad: .heavy,
            searchQueries: [
                AISearchQuery(query: "\(title) review", platform: .youtube, forStepIndex: 1),
                AISearchQuery(query: "\(title) practice questions", platform: .google, forStepIndex: 3),
            ]
        )
    }

    private func codingDecomposition(_ title: String) -> AIDecomposition {
        AIDecomposition(
            steps: [
                AIStep(title: "Read requirements and understand the problem", estimatedMinutes: 10),
                AIStep(title: "Plan approach and pseudocode", estimatedMinutes: 15),
                AIStep(title: "Set up project/files", estimatedMinutes: 5),
                AIStep(title: "Implement core logic", estimatedMinutes: 30),
                AIStep(title: "Test and debug", estimatedMinutes: 20),
                AIStep(title: "Clean up code and add comments", estimatedMinutes: 10),
            ],
            estimatedMinutes: 90,
            cognitiveLoad: .extreme,
            searchQueries: [
                AISearchQuery(query: "\(title) tutorial", platform: .youtube, forStepIndex: 1),
                AISearchQuery(query: "\(title) documentation", platform: .google, forStepIndex: 3),
            ]
        )
    }

    private func readingDecomposition(_ title: String) -> AIDecomposition {
        AIDecomposition(
            steps: [
                AIStep(title: "Skim headings and key sections", estimatedMinutes: 10),
                AIStep(title: "Read through the material carefully", estimatedMinutes: 30),
                AIStep(title: "Highlight and take notes on key points", estimatedMinutes: 15),
                AIStep(title: "Summarize main takeaways", estimatedMinutes: 10),
            ],
            estimatedMinutes: 65,
            cognitiveLoad: .moderate,
            searchQueries: [
                AISearchQuery(query: "\(title) summary", platform: .google, forStepIndex: 0),
            ]
        )
    }

    private func presentationDecomposition(_ title: String) -> AIDecomposition {
        AIDecomposition(
            steps: [
                AIStep(title: "Research and gather content", estimatedMinutes: 20),
                AIStep(title: "Create outline and structure slides", estimatedMinutes: 15),
                AIStep(title: "Design slides with visuals", estimatedMinutes: 25),
                AIStep(title: "Write speaker notes", estimatedMinutes: 15),
                AIStep(title: "Practice delivery and timing", estimatedMinutes: 15),
            ],
            estimatedMinutes: 90,
            cognitiveLoad: .heavy,
            searchQueries: [
                AISearchQuery(query: "\(title) presentation tips", platform: .youtube, forStepIndex: 4),
            ]
        )
    }

    private func exerciseDecomposition(_ title: String) -> AIDecomposition {
        AIDecomposition(
            steps: [
                AIStep(title: "Read all instructions carefully", estimatedMinutes: 5),
                AIStep(title: "Work through easier problems first", estimatedMinutes: 20),
                AIStep(title: "Tackle harder problems", estimatedMinutes: 25),
                AIStep(title: "Review answers and check work", estimatedMinutes: 10),
            ],
            estimatedMinutes: 60,
            cognitiveLoad: .moderate,
            searchQueries: [
                AISearchQuery(query: "\(title) help", platform: .google, forStepIndex: 2),
            ]
        )
    }

    private func genericDecomposition(_ title: String) -> AIDecomposition {
        AIDecomposition(
            steps: [
                AIStep(title: "Understand what's required", estimatedMinutes: 10),
                AIStep(title: "Gather materials and resources", estimatedMinutes: 10),
                AIStep(title: "Work on the main task", estimatedMinutes: 30),
                AIStep(title: "Review and finalize", estimatedMinutes: 10),
            ],
            estimatedMinutes: 60,
            cognitiveLoad: .moderate,
            searchQueries: [
                AISearchQuery(query: "\(title) how to", platform: .google, forStepIndex: 0),
            ]
        )
    }
}

enum AIServiceError: Error {
    case modelUnavailable
    case parsingFailed
}
