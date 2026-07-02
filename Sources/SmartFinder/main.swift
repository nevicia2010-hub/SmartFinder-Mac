import AppKit
import Darwin

if let localizationIndex = CommandLine.arguments.firstIndex(of: "--print-localization"),
   CommandLine.arguments.indices.contains(localizationIndex + 1) {
    let key = CommandLine.arguments[localizationIndex + 1]
    print(L10n.string(key, fallback: key))
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()

app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
