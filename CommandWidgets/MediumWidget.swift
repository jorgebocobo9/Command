import WidgetKit
import SwiftUI

struct MediumWidgetEntry: TimelineEntry {
    let date: Date
    let missions: [MediumMissionItem]
}

struct MediumMissionItem {
    let title: String
    let categoryHex: String
    let deadline: Date?
    let progress: Double
}

struct MediumWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MediumWidgetEntry {
        MediumWidgetEntry(date: .now, missions: [
            MediumMissionItem(title: "Math homework", categoryHex: "00D4FF", deadline: Date().addingTimeInterval(7200), progress: 0.3),
            MediumMissionItem(title: "Project report", categoryHex: "FF2D78", deadline: Date().addingTimeInterval(86400), progress: 0.6),
            MediumMissionItem(title: "Read chapter 5", categoryHex: "00FF88", deadline: nil, progress: 0)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (MediumWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MediumWidgetEntry>) -> Void) {
        let entry = MediumWidgetEntry(date: .now, missions: [])
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(1800)))
        completion(timeline)
    }
}

struct MediumWidgetView: View {
    let entry: MediumWidgetEntry

    var body: some View {
        HStack(spacing: 12) {
            // Mini radar placeholder
            ZStack {
                Circle()
                    .stroke(Color(hex: "2A2A35").opacity(0.5), lineWidth: 0.5)
                    .frame(width: 60, height: 60)
                Circle()
                    .stroke(Color(hex: "2A2A35").opacity(0.5), lineWidth: 0.5)
                    .frame(width: 40, height: 40)
                Circle()
                    .stroke(Color(hex: "2A2A35").opacity(0.5), lineWidth: 0.5)
                    .frame(width: 20, height: 20)
                Circle()
                    .fill(Color(hex: "F5F5F7"))
                    .frame(width: 3, height: 3)

                // Mission dots
                ForEach(0..<min(entry.missions.count, 5), id: \.self) { i in
                    Circle()
                        .fill(Color(hex: entry.missions[i].categoryHex))
                        .frame(width: 5, height: 5)
                        .offset(x: CGFloat(10 + i * 7), y: CGFloat(-5 + i * 8))
                }
            }
            .frame(width: 70)

            // Mission list
            VStack(alignment: .leading, spacing: 6) {
                if entry.missions.isEmpty {
                    Text("No active missions")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: "8E8E93"))
                } else {
                    ForEach(0..<min(entry.missions.count, 3), id: \.self) { i in
                        let mission = entry.missions[i]
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color(hex: mission.categoryHex))
                                .frame(width: 3, height: 20)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(mission.title)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color(hex: "F5F5F7"))
                                    .lineLimit(1)

                                if let deadline = mission.deadline {
                                    Text(deadline, style: .relative)
                                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                                        .foregroundStyle(Color(hex: "8E8E93"))
                                }
                            }

                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(12)
        .containerBackground(Color(hex: "0A0A0F"), for: .widget)
    }
}

struct CommandMediumWidget: Widget {
    let kind = "CommandMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MediumWidgetProvider()) { entry in
            MediumWidgetView(entry: entry)
        }
        .configurationDisplayName("Mission Radar")
        .description("Mini radar with your top missions")
        .supportedFamilies([.systemMedium])
    }
}
