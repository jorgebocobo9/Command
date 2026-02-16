import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil
    var accentColor: Color = CommandColors.school

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.06))
                    .frame(width: 80, height: 80)
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .thin))
                    .foregroundStyle(accentColor.opacity(0.5))
            }
            .padding(.bottom, 4)

            Text(title)
                .font(CommandTypography.headline)
                .foregroundStyle(CommandColors.textSecondary)

            Text(subtitle)
                .font(CommandTypography.caption)
                .foregroundStyle(CommandColors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if let actionLabel, let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(CommandTypography.caption)
                        .foregroundStyle(CommandColors.textPrimary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(accentColor.opacity(0.15))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(accentColor.opacity(0.3), lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}
