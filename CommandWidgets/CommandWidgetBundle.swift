// Placeholder — Frontend agent will replace
import WidgetKit
import SwiftUI

@main
struct CommandWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Widgets will be added by Frontend agent
        CommandPlaceholderWidget()
    }
}

struct CommandPlaceholderWidget: Widget {
    let kind = "CommandWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PlaceholderProvider()) { entry in
            Text("Command")
        }
        .configurationDisplayName("Command")
        .description("Track your missions")
        .supportedFamilies([.systemSmall])
    }
}

struct PlaceholderEntry: TimelineEntry {
    let date: Date
}

struct PlaceholderProvider: TimelineProvider {
    func placeholder(in context: Context) -> PlaceholderEntry { PlaceholderEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (PlaceholderEntry) -> Void) { completion(PlaceholderEntry(date: .now)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<PlaceholderEntry>) -> Void) {
        completion(Timeline(entries: [PlaceholderEntry(date: .now)], policy: .atEnd))
    }
}
