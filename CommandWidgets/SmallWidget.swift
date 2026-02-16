import WidgetKit
import SwiftUI

struct SmallWidgetEntry: TimelineEntry {
    let date: Date
    let nextDeadline: Date?
    let missionTitle: String?
    let streakCount: Int
}

struct SmallWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SmallWidgetEntry {
        SmallWidgetEntry(date: .now, nextDeadline: Date().addingTimeInterval(3600), missionTitle: "Sample Mission", streakCount: 5)
    }

    func getSnapshot(in context: Context, completion: @escaping (SmallWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SmallWidgetEntry>) -> Void) {
        // In production, read from shared SwiftData container via App Group
        let entry = SmallWidgetEntry(date: .now, nextDeadline: nil, missionTitle: nil, streakCount: 0)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(1800)))
        completion(timeline)
    }
}

struct SmallWidgetView: View {
    let entry: SmallWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "scope")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "00D4FF"))
                Text("Command")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "8E8E93"))
            }

            Spacer()

            if let title = entry.missionTitle, let deadline = entry.nextDeadline {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "F5F5F7"))
                    .lineLimit(2)

                Text(deadline, style: .relative)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(deadline.timeIntervalSinceNow < 3600 ? Color(hex: "FF3B30") : Color(hex: "FF9500"))
            } else {
                Text("No upcoming deadlines")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(hex: "8E8E93"))
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "FF9500"))
                Text("\(entry.streakCount) day streak")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color(hex: "8E8E93"))
            }
        }
        .padding(12)
        .containerBackground(Color(hex: "0A0A0F"), for: .widget)
    }
}

struct CommandSmallWidget: Widget {
    let kind = "CommandSmallWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SmallWidgetProvider()) { entry in
            SmallWidgetView(entry: entry)
        }
        .configurationDisplayName("Next Deadline")
        .description("Shows your next deadline and streak count")
        .supportedFamilies([.systemSmall])
    }
}
