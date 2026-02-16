import Foundation
import SwiftData
import SwiftUI

enum FocusState: Equatable {
    case ready
    case focusing
    case paused
    case onBreak
    case completed
}

@Observable @MainActor
final class FocusViewModel {
    var focusState: FocusState = .ready
    var totalSeconds: Int = 25 * 60
    var remainingSeconds: Int = 25 * 60
    var breakDuration: Int = 5
    var sessionsCompleted: Int = 0
    var currentSession: FocusSession?
    var mission: Mission?

    private var timer: Timer?

    var accentColor: Color {
        guard let mission else { return CommandColors.school }
        return CommandColors.categoryColor(mission.category)
    }

    func configure(mission: Mission, minutes: Int = 25) {
        self.mission = mission
        self.totalSeconds = minutes * 60
        self.remainingSeconds = minutes * 60

        // Adaptive break based on cognitive load
        switch mission.cognitiveLoad {
        case .heavy, .extreme:
            breakDuration = 10
        case .moderate:
            breakDuration = 7
        default:
            breakDuration = 5
        }
    }

    func start(context: ModelContext) {
        guard let mission else { return }
        focusState = .focusing

        let session = FocusSession(mission: mission, plannedMinutes: totalSeconds / 60)
        context.insert(session)
        currentSession = session

        startTimer()
    }

    func pause() {
        focusState = .paused
        stopTimer()
    }

    func resume() {
        focusState = .focusing
        startTimer()
    }

    func takeBreak() {
        focusState = .onBreak
        stopTimer()
        if let session = currentSession {
            session.breaksTaken += 1
        }
    }

    func continueAfterBreak() {
        focusState = .focusing
        startTimer()
    }

    private let energyService = EnergyService()

    func complete(context: ModelContext) {
        stopTimer()
        focusState = .completed
        sessionsCompleted += 1

        if let session = currentSession {
            session.endedAt = Date()
            session.wasCompleted = true
            try? context.save()

            // Record session to energy profile
            energyService.recordSession(session, context: context)
        }
    }

    func endEarly(context: ModelContext) {
        stopTimer()
        focusState = .completed

        if let session = currentSession {
            session.endedAt = Date()
            session.wasCompleted = false
            try? context.save()

            // Record partial session to energy profile
            energyService.recordSession(session, context: context)
        }
    }

    func reset() {
        stopTimer()
        focusState = .ready
        remainingSeconds = totalSeconds
        currentSession = nil
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
            } else {
                self.stopTimer()
                self.focusState = .onBreak
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
