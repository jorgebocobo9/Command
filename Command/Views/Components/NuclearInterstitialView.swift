import SwiftUI

struct NuclearInterstitialView: View {
    let mission: Mission
    let onAcknowledge: () -> Void

    @State private var pulsing = false

    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.95).ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Pulsing warning icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(CommandColors.urgent)
                    .scaleEffect(pulsing ? 1.1 : 1.0)
                    .glow(CommandColors.urgent, radius: 16, intensity: pulsing ? 0.8 : 0.3)

                VStack(spacing: 8) {
                    Text("NUCLEAR ALERT")
                        .font(CommandTypography.caption)
                        .foregroundStyle(CommandColors.urgent)
                        .tracking(3)

                    Text(mission.title)
                        .font(CommandTypography.largeTitle)
                        .foregroundStyle(CommandColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                if let deadline = mission.deadline {
                    VStack(spacing: 4) {
                        if mission.isOverdue {
                            Text("OVERDUE")
                                .font(CommandTypography.caption)
                                .foregroundStyle(CommandColors.urgent)
                                .tracking(2)
                        }
                        AnimatedCountdown(targetDate: deadline)
                            .scaleEffect(1.5)
                    }
                }

                // Step progress
                if !mission.steps.isEmpty {
                    VStack(spacing: 8) {
                        Text("\(mission.steps.filter(\.isCompleted).count) of \(mission.steps.count) steps complete")
                            .font(CommandTypography.body)
                            .foregroundStyle(CommandColors.textSecondary)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(CommandColors.urgent.opacity(0.2))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 3)
                                    .fill(CommandColors.urgent)
                                    .frame(width: geo.size.width * mission.stepProgress, height: 6)
                            }
                        }
                        .frame(height: 6)
                        .padding(.horizontal, 40)
                    }
                }

                Spacer()

                // Must acknowledge
                Button(action: onAcknowledge) {
                    Text("I will handle this now")
                        .font(CommandTypography.headline)
                        .foregroundStyle(CommandColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(CommandColors.urgent.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(CommandColors.urgent.opacity(0.5), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)

                Text("This mission has nuclear aggression level. You must acknowledge to continue.")
                    .font(CommandTypography.caption)
                    .foregroundStyle(CommandColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(CommandAnimations.pulse) {
                pulsing = true
            }
        }
    }
}
