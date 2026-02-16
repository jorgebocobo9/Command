import Foundation
import SwiftData
import SwiftUI

@Observable @MainActor
final class ClassroomViewModel {
    var isConnected = false
    var isSyncing = false
    var lastSynced: Date?
    var syncError: String?

    private let classroomService: ClassroomService
    private let syncService: SyncService

    init() {
        let service = ClassroomService()
        self.classroomService = service
        self.syncService = SyncService(classroomService: service)

        // Check if already authenticated from a previous session
        Task { @MainActor [service] in
            let authed = await service.isAuthenticated
            self.isConnected = authed
        }
    }

    func connect() async {
        do {
            try await classroomService.authenticate()
            isConnected = true
        } catch {
            syncError = "Failed to connect: \(error.localizedDescription)"
            isConnected = false
        }
    }

    func disconnect() {
        Task { await classroomService.signOut() }
        isConnected = false
        lastSynced = nil
    }

    func sync(context: ModelContext) async {
        guard !isSyncing else { return }
        guard isConnected else {
            syncError = "Not connected to Google Classroom"
            return
        }
        isSyncing = true
        syncError = nil

        do {
            try await syncService.syncClassroom(context: context)
            lastSynced = Date()
        } catch {
            syncError = "Sync failed: \(error.localizedDescription)"
        }

        isSyncing = false
    }
}
