import Foundation
import SwiftData
import SwiftUI

@Observable @MainActor
final class ClassroomViewModel {
    var isConnected = false
    var isSyncing = false
    var lastSynced: Date?
    var syncError: String?

    func connect() async {
        // ClassroomService.authenticate() will be wired by manager during integration
        // For now, this is a placeholder
        isConnected = true
    }

    func disconnect() {
        isConnected = false
        lastSynced = nil
    }

    func sync(context: ModelContext) async {
        guard !isSyncing else { return }
        isSyncing = true
        syncError = nil

        // SyncService.syncClassroom() will be wired by manager during integration
        // For now, simulate sync delay
        try? await Task.sleep(for: .seconds(1))

        lastSynced = Date()
        isSyncing = false
    }
}
