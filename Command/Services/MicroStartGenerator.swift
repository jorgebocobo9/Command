import Foundation

@MainActor final class MicroStartGenerator {
    private let aiService: any AIServiceProtocol

    init(aiService: any AIServiceProtocol) {
        self.aiService = aiService
    }

    func generate(for title: String) async -> String {
        do {
            return try await aiService.generateMicroStart(for: title)
        } catch {
            return fallbackMicroStart(for: title)
        }
    }

    private func fallbackMicroStart(for title: String) -> String {
        let templates = [
            "Just open the document for '\(title)' and read the first paragraph.",
            "Write one sentence about '\(title)' — just one.",
            "Set a 2-minute timer and brainstorm 3 bullet points for '\(title)'.",
            "Open a blank page and write the title: '\(title)'.",
            "Find one resource about '\(title)' and bookmark it.",
            "Write down what you already know about '\(title)'.",
            "Outline 3 sections you think '\(title)' needs.",
            "Spend 60 seconds thinking about the first step for '\(title)'."
        ]
        return templates.randomElement()!
    }
}
