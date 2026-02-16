import SwiftUI

struct SyncStatusView: View {
    let lastSynced: Date?
    let isSyncing: Bool
    let onSync: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SYNC STATUS")
                    .font(CommandTypography.caption)
                    .foregroundStyle(CommandColors.textTertiary)
                    .tracking(1.5)

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
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 16))
                        .foregroundStyle(CommandColors.school)
                }
            }
            .buttonStyle(.plain)
            .disabled(isSyncing)
        }
        .padding(12)
        .background(CommandColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
