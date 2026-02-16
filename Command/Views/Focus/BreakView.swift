import SwiftUI

struct BreakView: View {
    let breakDuration: Int
    let cognitiveLoad: CognitiveLoad?
    let onSkip: () -> Void
    let onContinue: () -> Void

    @State private var remainingSeconds: Int = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var movementPrompt: String {
        switch cognitiveLoad {
        case .heavy, .extreme:
            return "Stand up and stretch. Walk around for a minute."
        case .moderate:
            return "Look away from the screen. Rest your eyes."
        default:
            return "Take a breath. You earned this."
        }
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("BREAK TIME")
                .font(CommandTypography.caption)
                .foregroundStyle(CommandColors.textTertiary)
                .tracking(2)

            Text(formattedTime)
                .font(.system(size: 56, weight: .ultraLight, design: .monospaced))
                .foregroundStyle(CommandColors.textPrimary)
                .contentTransition(.numericText())

            Text(movementPrompt)
                .font(CommandTypography.body)
                .foregroundStyle(CommandColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            VStack(spacing: 12) {
                Button(action: onContinue) {
                    Text("Continue Focus")
                        .font(CommandTypography.headline)
                        .foregroundStyle(CommandColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(CommandColors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Button(action: onSkip) {
                    Text("End Session")
                        .font(CommandTypography.body)
                        .foregroundStyle(CommandColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(CommandColors.background)
        .onAppear {
            remainingSeconds = breakDuration * 60
        }
        .onReceive(timer) { _ in
            if remainingSeconds > 0 {
                withAnimation(CommandAnimations.springQuick) {
                    remainingSeconds -= 1
                }
            } else {
                onContinue()
            }
        }
    }

    private var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
