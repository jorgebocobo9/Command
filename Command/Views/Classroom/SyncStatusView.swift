import SwiftUI

struct SyncStatusView: View {
    let lastSynced: Date?
    let isSyncing: Bool
    let onSync: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Status dot
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .glow(statusColor, radius: 4, intensity: 0.4)

            VStack(alignment: .leading, spacing: 2) {
                if let lastSynced {
                    Text("Last synced \(lastSynced, style: .relative) ago")
                        .font(CommandTypography.caption)
                        .foregroundStyle(CommandColors.textSecondary)
                } else {
                    Text("Never synced")
                        .font(CommandTypography.caption)
                        .foregroundStyle(CommandColors.warning)
                }
            }

            Spacer()

            Button(action: onSync) {
                if isSyncing {
                    ProgressView()
                        .tint(CommandColors.school)
                        .scaleEffect(0.8)
                } else {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12))
                        Text("Sync")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(CommandColors.school)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(CommandColors.school.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            .buttonStyle(.plain)
            .disabled(isSyncing)
        }
        .padding(12)
        .background(CommandColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(CommandColors.surfaceBorder, lineWidth: 0.5)
        )
    }

    private var statusColor: Color {
        if isSyncing { return CommandColors.school }
        if lastSynced == nil { return CommandColors.warning }
        return CommandColors.success
    }
}
