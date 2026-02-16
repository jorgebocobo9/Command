import SwiftUI

struct UrgentBannerView: View {
    let mission: Mission
    let onTap: () -> Void
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        if appeared {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(CommandColors.urgent)
                        .frame(width: 4, height: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("URGENT")
                            .font(CommandTypography.caption)
                            .foregroundStyle(CommandColors.urgent)
                            .tracking(1.5)

                        Text(mission.title)
                            .font(CommandTypography.headline)
                            .foregroundStyle(CommandColors.textPrimary)
                            .lineLimit(1)
                    }

                    Spacer()

                    if let deadline = mission.deadline {
                        AnimatedCountdown(targetDate: deadline)
                    }

                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(CommandColors.textTertiary)
                            .frame(width: 28, height: 28)
                            .background(CommandColors.surfaceElevated)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(CommandColors.surface)
                .overlay(
                    Rectangle()
                        .fill(CommandColors.urgent.opacity(0.3))
                        .frame(height: 1),
                    alignment: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .glow(CommandColors.urgent, radius: 8, intensity: 0.3)
                .onTapGesture(perform: onTap)
            }
            .padding(.horizontal)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    func show() -> UrgentBannerView {
        var view = self
        view._appeared = State(initialValue: true)
        return view
    }
}
