import Foundation

/// The extension's side of the shared widget intents. They run in the app, which has the
/// real `WidgetActions`, so nothing happens here.
enum WidgetActions {
    static func done(_ id: UUID) async {}
    static func openCapture() async {}
}
