import ActivityKit
import SwiftUI
import WidgetKit

struct FocusActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingSeconds: Int
        var missionTitle: String
        var categoryHex: String
        var isPaused: Bool
    }

    var totalMinutes: Int
    var stepTitle: String?
}

struct FocusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            // Lock screen presentation
            HStack(spacing: 12) {
                // Timer
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.missionTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "F5F5F7"))
                        .lineLimit(1)

                    if let step = context.attributes.stepTitle {
                        Text(step)
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "8E8E93"))
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Countdown
                Text(formatTime(context.state.remainingSeconds))
                    .font(.system(size: 28, weight: .light, design: .monospaced))
                    .foregroundStyle(context.state.isPaused ? Color(hex: "FF9500") : Color(hex: context.state.categoryHex))

                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color(hex: context.state.categoryHex).opacity(0.2), lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: Double(context.state.remainingSeconds) / Double(context.attributes.totalMinutes * 60))
                        .stroke(Color(hex: context.state.categoryHex), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 36, height: 36)
            }
            .padding(16)
            .activityBackgroundTint(Color(hex: "0A0A0F"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.missionTitle)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: "F5F5F7"))
                            .lineLimit(1)

                        if context.state.isPaused {
                            Text("Paused")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color(hex: "FF9500"))
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(formatTime(context.state.remainingSeconds))
                        .font(.system(size: 22, weight: .light, design: .monospaced))
                        .foregroundStyle(Color(hex: context.state.categoryHex))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: Double(context.state.remainingSeconds), total: Double(context.attributes.totalMinutes * 60))
                        .tint(Color(hex: context.state.categoryHex))
                }
            } compactLeading: {
                Image(systemName: "scope")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: context.state.categoryHex))
            } compactTrailing: {
                Text(formatTime(context.state.remainingSeconds))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(hex: context.state.categoryHex))
            } minimal: {
                Image(systemName: "scope")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: context.state.categoryHex))
            }
        }
    }
}

private func formatTime(_ seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    return String(format: "%02d:%02d", m, s)
}
