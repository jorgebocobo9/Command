import SwiftUI

struct AnimatedCountdown: View {
    let targetDate: Date
    @State private var timeRemaining: TimeInterval = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(formattedTime)
            .font(CommandTypography.mono)
            .foregroundStyle(urgencyColor)
            .contentTransition(.numericText())
            .onReceive(timer) { _ in
                withAnimation(CommandAnimations.springQuick) {
                    timeRemaining = targetDate.timeIntervalSinceNow
                }
            }
            .onAppear {
                timeRemaining = targetDate.timeIntervalSinceNow
            }
    }

    private var formattedTime: String {
        if timeRemaining <= 0 { return "OVERDUE" }

        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        let seconds = Int(timeRemaining) % 60

        if hours > 24 {
            let days = hours / 24
            return "\(days)d \(hours % 24)h"
        } else if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private var urgencyColor: Color {
        if timeRemaining <= 0 { return CommandColors.urgent }
        if timeRemaining < 3600 { return CommandColors.urgent }
        if timeRemaining < 86400 { return CommandColors.warning }
        return CommandColors.textSecondary
    }
}
