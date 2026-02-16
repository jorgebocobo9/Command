import ActivityKit
import SwiftUI
import WidgetKit

struct DeadlineActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingSeconds: Int
        var isOverdue: Bool
    }

    var missionTitle: String
    var categoryHex: String
    var aggressionLevel: String
}

struct DeadlineLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DeadlineActivityAttributes.self) { context in
            // Lock screen presentation
            HStack(spacing: 12) {
                // Mission info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        if context.state.isOverdue {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color(hex: "FF3B30"))
                        }
                        Text(context.state.isOverdue ? "OVERDUE" : "DEADLINE")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(context.state.isOverdue ? Color(hex: "FF3B30") : Color(hex: "48484A"))
                            .tracking(1)
                    }

                    Text(context.attributes.missionTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "F5F5F7"))
                        .lineLimit(1)
                }

                Spacer()

                // Countdown
                Text(formatDeadlineTime(context.state.remainingSeconds))
                    .font(.system(size: 28, weight: .light, design: .monospaced))
                    .foregroundStyle(context.state.isOverdue ? Color(hex: "FF3B30") : Color(hex: "FF9500"))
            }
            .padding(16)
            .activityBackgroundTint(Color(hex: "0A0A0F"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.missionTitle)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: "F5F5F7"))
                            .lineLimit(1)

                        Text(context.state.isOverdue ? "OVERDUE" : "Due soon")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(context.state.isOverdue ? Color(hex: "FF3B30") : Color(hex: "FF9500"))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(formatDeadlineTime(context.state.remainingSeconds))
                        .font(.system(size: 22, weight: .light, design: .monospaced))
                        .foregroundStyle(context.state.isOverdue ? Color(hex: "FF3B30") : Color(hex: "FF9500"))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.isOverdue {
                        Text("This mission needs your attention now")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "8E8E93"))
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.isOverdue ? "exclamationmark.triangle.fill" : "clock")
                    .font(.system(size: 12))
                    .foregroundStyle(context.state.isOverdue ? Color(hex: "FF3B30") : Color(hex: "FF9500"))
            } compactTrailing: {
                Text(formatDeadlineTime(context.state.remainingSeconds))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(context.state.isOverdue ? Color(hex: "FF3B30") : Color(hex: "FF9500"))
            } minimal: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "FF3B30"))
            }
        }
    }
}

private func formatDeadlineTime(_ seconds: Int) -> String {
    let absSeconds = abs(seconds)
    let hours = absSeconds / 3600
    let minutes = (absSeconds % 3600) / 60

    let prefix = seconds < 0 ? "+" : ""

    if hours > 0 {
        return "\(prefix)\(hours)h \(minutes)m"
    } else {
        let secs = absSeconds % 60
        return "\(prefix)\(minutes):\(String(format: "%02d", secs))"
    }
}
