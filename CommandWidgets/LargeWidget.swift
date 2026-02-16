import WidgetKit
import SwiftUI

struct LargeWidgetEntry: TimelineEntry {
    let date: Date
    let missions: [LargeMissionItem]
    let streakCount: Int
}

struct LargeMissionItem {
    let title: String
    let categoryHex: String
    let deadline: Date?
    let stepsCompleted: Int
    let stepsTotal: Int
    let isOverdue: Bool
}

struct LargeWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> LargeWidgetEntry {
        LargeWidgetEntry(date: .now, missions: [
            LargeMissionItem(title: "Math homework Ch. 5", categoryHex: "00D4FF", deadline: Date().addingTimeInterval(3600), stepsCompleted: 2, stepsTotal: 5, isOverdue: false),
            LargeMissionItem(title: "Project report draft", categoryHex: "FF2D78", deadline: Date().addingTimeInterval(86400), stepsCompleted: 1, stepsTotal: 4, isOverdue: false),
            LargeMissionItem(title: "Read biology chapter", categoryHex: "00D4FF", deadline: Date().addingTimeInterval(172800), stepsCompleted: 0, stepsTotal: 3, isOverdue: false),
            LargeMissionItem(title: "Gym routine", categoryHex: "00FF88", deadline: nil, stepsCompleted: 0, stepsTotal: 0, isOverdue: false),
        ], streakCount: 7)
    }

    func getSnapshot(in context: Context, completion: @escaping (LargeWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LargeWidgetEntry>) -> Void) {
        let entry = LargeWidgetEntry(date: .now, missions: [], streakCount: 0)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(1800)))
        completion(timeline)
    }
}

struct LargeWidgetView: View {
    let entry: LargeWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "scope")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: "00D4FF"))
                    Text("TODAY'S MISSIONS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color(hex: "48484A"))
                        .tracking(1.5)
                }

                Spacer()

                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(Color(hex: "FF9500"))
                    Text("\(entry.streakCount)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color(hex: "FF9500"))
                }
            }

            if entry.missions.isEmpty {
                Spacer()
                Text("No missions for today")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "8E8E93"))
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ForEach(0..<min(entry.missions.count, 5), id: \.self) { i in
                    LargeMissionRow(mission: entry.missions[i])
                }
                Spacer()
            }
        }
        .padding(14)
        .containerBackground(Color(hex: "0A0A0F"), for: .widget)
    }
}

struct LargeMissionRow: View {
    let mission: LargeMissionItem

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color(hex: mission.categoryHex))
                .frame(width: 3, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(mission.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "F5F5F7"))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if mission.stepsTotal > 0 {
                        Text("\(mission.stepsCompleted)/\(mission.stepsTotal)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color(hex: "8E8E93"))
                    }

                    if let deadline = mission.deadline {
                        Text(deadline, style: .relative)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(mission.isOverdue ? Color(hex: "FF3B30") : Color(hex: "8E8E93"))
                    }
                }
            }

            Spacer()

            if mission.stepsTotal > 0 {
                ZStack {
                    Circle()
                        .stroke(Color(hex: mission.categoryHex).opacity(0.15), lineWidth: 2)
                    Circle()
                        .trim(from: 0, to: Double(mission.stepsCompleted) / Double(mission.stepsTotal))
                        .stroke(Color(hex: mission.categoryHex), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 22, height: 22)
            }
        }
    }
}

struct CommandLargeWidget: Widget {
    let kind = "CommandLargeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LargeWidgetProvider()) { entry in
            LargeWidgetView(entry: entry)
        }
        .configurationDisplayName("Mission List")
        .description("Today's full mission list with progress")
        .supportedFamilies([.systemLarge])
    }
}
