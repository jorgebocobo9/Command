import SwiftUI

struct FocusTimerView: View {
    let totalSeconds: Int
    let remainingSeconds: Int
    let accentColor: Color
    let isPaused: Bool

    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(remainingSeconds) / Double(totalSeconds)
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(accentColor.opacity(0.1), lineWidth: 6)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)

            // Time display
            VStack(spacing: 4) {
                Text(formattedTime)
                    .font(.system(size: 48, weight: .light, design: .monospaced))
                    .foregroundStyle(CommandColors.textPrimary)
                    .contentTransition(.numericText())

                if isPaused {
                    Text("PAUSED")
                        .font(CommandTypography.caption)
                        .foregroundStyle(CommandColors.warning)
                        .tracking(2)
                }
            }
        }
        .glow(accentColor, radius: 12, intensity: isPaused ? 0.1 : 0.3)
    }

    private var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
