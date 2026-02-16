import Foundation
import SwiftData
import SwiftUI
import ActivityKit

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
    private var liveActivity: Activity<FocusActivityAttributes>?

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

        startLiveActivity()
        startTimer()
    }

    func pause() {
        focusState = .paused
        stopTimer()
        updateLiveActivity()
    }

    func resume() {
        focusState = .focusing
        startTimer()
        updateLiveActivity()
    }

    func takeBreak() {
        focusState = .onBreak
        stopTimer()
        if let session = currentSession {
            session.breaksTaken += 1
        }
        endLiveActivity()
    }

    func continueAfterBreak() {
        focusState = .focusing
        startLiveActivity()
        startTimer()
    }

    private let energyService = EnergyService()

    func complete(context: ModelContext) {
        stopTimer()
        focusState = .completed
        sessionsCompleted += 1
        endLiveActivity()

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
        endLiveActivity()

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
        endLiveActivity()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                    self.updateLiveActivity()
                } else {
                    self.stopTimer()
                    self.focusState = .onBreak
                    self.endLiveActivity()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Live Activity

    private func categoryHex() -> String {
        guard let mission else { return "00D4FF" }
        switch mission.category {
        case .school: return "00D4FF"
        case .work: return "FF2D78"
        case .personal: return "00FF88"
        }
    }

    private func startLiveActivity() {
        guard let mission else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let nextStep = mission.steps
            .sorted(by: { $0.orderIndex < $1.orderIndex })
            .first(where: { !$0.isCompleted })

        let attributes = FocusActivityAttributes(
            totalMinutes: totalSeconds / 60,
            stepTitle: nextStep?.title
        )

        let state = FocusActivityAttributes.ContentState(
            remainingSeconds: remainingSeconds,
            missionTitle: mission.title,
            categoryHex: categoryHex(),
            isPaused: false
        )

        do {
            liveActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            // Live Activity not available — silently continue
        }
    }

    private func updateLiveActivity() {
        guard let mission, let activity = liveActivity else { return }

        let state = FocusActivityAttributes.ContentState(
            remainingSeconds: remainingSeconds,
            missionTitle: mission.title,
            categoryHex: categoryHex(),
            isPaused: focusState == .paused
        )

        Task {
            let content = ActivityContent(state: state, staleDate: nil)
            await activity.update(content)
        }
    }

    private func endLiveActivity() {
        guard let activity = liveActivity else { return }
        Task {
            await activity.end(ActivityContent(state: activity.content.state, staleDate: nil), dismissalPolicy: .immediate)
        }
        liveActivity = nil
    }
}
