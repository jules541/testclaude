import WidgetKit
import SwiftUI

struct GoalPlanWidget: Widget {
    let kind: String = "GoalPlanWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            GoalPlanWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Goal Plan")
        .description("Track your quarterly goals")
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = SimpleEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct GoalPlanWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        Text("Goal Plan")
            .font(.headline)
    }
}

#Preview(as: .systemSmall) {
    GoalPlanWidget()
} timeline: {
    SimpleEntry(date: .now)
}
