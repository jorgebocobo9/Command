import Foundation
import SwiftData

actor EnergyService {
    func recordSession(_ session: FocusSession, context: ModelContext) {
        guard let duration = session.durationMinutes, duration > 0 else { return }

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: session.startedAt)
        let weekday = calendar.component(.weekday, from: session.startedAt)

        let productivity = session.wasCompleted ? 1.0 : Double(duration) / Double(session.plannedMinutes)

        let descriptor = FetchDescriptor<EnergyProfile>(
            predicate: #Predicate { $0.hourOfDay == hour && $0.dayOfWeek == weekday }
        )

        if let existing = try? context.fetch(descriptor).first {
            existing.update(with: productivity)
        } else {
            let profile = EnergyProfile(hourOfDay: hour, dayOfWeek: weekday)
            profile.update(with: productivity)
            context.insert(profile)
        }

        try? context.save()
    }

    func currentEnergyLevel(context: ModelContext) -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let weekday = calendar.component(.weekday, from: Date())

        let descriptor = FetchDescriptor<EnergyProfile>(
            predicate: #Predicate { $0.hourOfDay == hour && $0.dayOfWeek == weekday }
        )

        return (try? context.fetch(descriptor).first?.averageProductivity) ?? 0.5
    }

    func suggestMissionOrder(_ missions: [Mission], context: ModelContext) -> [Mission] {
        let energy = currentEnergyLevel(context: context)

        return missions.sorted { a, b in
            // Overdue missions always first
            if a.isOverdue != b.isOverdue { return a.isOverdue }

            // During high energy, prioritize heavy tasks
            if energy > 0.7 {
                let aLoad = a.cognitiveLoad?.sortOrder ?? 1
                let bLoad = b.cognitiveLoad?.sortOrder ?? 1
                if aLoad != bLoad { return aLoad > bLoad }
            }

            // During low energy, prioritize light tasks
            if energy < 0.4 {
                let aLoad = a.cognitiveLoad?.sortOrder ?? 1
                let bLoad = b.cognitiveLoad?.sortOrder ?? 1
                if aLoad != bLoad { return aLoad < bLoad }
            }

            // Then by deadline proximity
            let aDeadline = a.deadline ?? .distantFuture
            let bDeadline = b.deadline ?? .distantFuture
            return aDeadline < bDeadline
        }
    }
}

extension CognitiveLoad {
    var sortOrder: Int {
        switch self {
        case .light: return 1
        case .moderate: return 2
        case .heavy: return 3
        case .extreme: return 4
        }
    }
}
