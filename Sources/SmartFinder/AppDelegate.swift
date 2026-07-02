import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var mainWindowController: MainWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = MainWindowController(startURL: Self.startURL())
        mainWindowController = controller
        controller.showWindow(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private static func startURL() -> URL {
        let arguments = CommandLine.arguments
        if let pathIndex = arguments.firstIndex(of: "--path"),
           arguments.indices.contains(pathIndex + 1) {
            let path = NSString(string: arguments[pathIndex + 1]).expandingTildeInPath
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser
    }
}
