import WidgetKit
import SwiftUI

@main
struct CommandWidgetBundle: WidgetBundle {
    var body: some Widget {
        CommandSmallWidget()
        CommandMediumWidget()
        CommandLargeWidget()
        FocusLiveActivity()
        DeadlineLiveActivity()
    }
}
