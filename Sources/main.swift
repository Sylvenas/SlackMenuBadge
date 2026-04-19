import AppKit

@MainActor
final class SlackMenuBadgeApp: NSObject, NSApplicationDelegate {
    private let pollInterval: TimeInterval = 5
    private let unreadProvider = SlackUnreadProvider()

    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var statusIcon: NSImage?
    private let statusFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .medium)

    func applicationDidFinishLaunching(_ notification: Notification) {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.font = statusFont
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.imageHugsTitle = true
        statusItem.button?.title = ""

        configureMenu()
        loadStatusIcon()
        refreshStatus()

        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshStatus()
            }
        }
    }

    private func configureMenu() {
        let menu = NSMenu()

        let refreshItem = NSMenuItem(
            title: "Refresh Now",
            action: #selector(handleRefresh),
            keyEquivalent: "r"
        )
        refreshItem.target = self
        menu.addItem(refreshItem)

        let openSlackItem = NSMenuItem(
            title: "Open Slack",
            action: #selector(handleOpenSlack),
            keyEquivalent: "o"
        )
        openSlackItem.target = self
        menu.addItem(openSlackItem)

        let permissionItem = NSMenuItem(
            title: "Accessibility Setup",
            action: #selector(handleOpenAccessibilitySettings),
            keyEquivalent: ","
        )
        permissionItem.target = self
        menu.addItem(permissionItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit SlackMenuBadge",
            action: #selector(handleQuit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func refreshStatus() {
        let result = unreadProvider.fetchUnreadCount()
        updateTitle(with: result)
        updateMenuHints(for: result)
    }

    private func updateTitle(with result: SlackUnreadResult) {
        guard let button = statusItem.button else { return }
        button.image = statusIcon ?? fallbackStatusIcon()
        button.imagePosition = .imageLeft

        switch result {
        case .count(let unreadCount):
            button.attributedTitle = makeStatusText(unreadCount > 0 ? "\(unreadCount)" : "")
            button.toolTip = unreadCount > 0 ? "Slack unread: \(unreadCount)" : "Slack: no unread messages"
        case .slackNotRunning:
            button.attributedTitle = makeStatusText("")
            button.toolTip = "Slack is not running"
        case .permissionRequired:
            button.attributedTitle = makeStatusText("?")
            button.toolTip = "Accessibility permission is required to read the Dock badge"
        case .unavailable:
            button.attributedTitle = makeStatusText("")
            button.toolTip = "Unread badge is unavailable"
        }
    }

    private func makeStatusText(_ string: String) -> NSAttributedString {
        NSAttributedString(
            string: string,
            attributes: [
                .font: statusFont,
                .kern: -0.2,
            ]
        )
    }

    private func loadStatusIcon() {
        guard let icon = loadBundledStatusIcon() else {
            statusIcon = fallbackStatusIcon()
            return
        }
        statusIcon = icon
    }

    private func loadBundledStatusIcon() -> NSImage? {
        let candidates = [
            Bundle.main.url(forResource: "slack-icon", withExtension: "png"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("AppResources/slack-icon.png"),
        ]

        for url in candidates.compactMap({ $0 }) {
            guard let image = NSImage(contentsOf: url) else { continue }
            return makeStatusBarIcon(from: image)
        }
        return nil
    }

    private func fallbackStatusIcon() -> NSImage? {
        let image = NSImage(systemSymbolName: "message.fill", accessibilityDescription: "Slack")
        guard let image else { return nil }
        return makeStatusBarIcon(from: image)
    }

    private func makeStatusBarIcon(from source: NSImage) -> NSImage? {
        let canvasSize = NSSize(width: 18, height: 18)
        let glyphSize = NSSize(width: 14, height: 14)

        let image = NSImage(size: canvasSize)
        image.lockFocus()

        NSColor.clear.set()
        NSBezierPath(rect: NSRect(origin: .zero, size: canvasSize)).fill()

        let origin = NSPoint(
            x: (canvasSize.width - glyphSize.width) / 2,
            y: (canvasSize.height - glyphSize.height) / 2
        )

        source.draw(
            in: NSRect(origin: origin, size: glyphSize),
            from: NSRect(origin: .zero, size: source.size),
            operation: .sourceOver,
            fraction: 1
        )

        image.unlockFocus()
        image.isTemplate = true
        image.size = canvasSize
        return image
    }

    private func updateMenuHints(for result: SlackUnreadResult) {
        guard let menu = statusItem.menu else { return }
        if menu.items.count < 5 { return }

        let refreshItem = menu.items[0]
        let openSlackItem = menu.items[1]
        let permissionItem = menu.items[2]

        switch result {
        case .count(let unreadCount):
            refreshItem.title = unreadCount > 0 ? "Refresh Now (\(unreadCount))" : "Refresh Now"
            openSlackItem.isHidden = false
            permissionItem.isHidden = true
        case .permissionRequired:
            refreshItem.title = "Refresh Now"
            openSlackItem.isHidden = false
            permissionItem.isHidden = false
        case .slackNotRunning, .unavailable:
            refreshItem.title = "Refresh Now"
            openSlackItem.isHidden = false
            permissionItem.isHidden = true
        }
    }

    @objc
    private func handleRefresh() {
        refreshStatus()
    }

    @objc
    private func handleOpenSlack() {
        NSWorkspace.shared.openApplication(
            at: URL(fileURLWithPath: "/Applications/Slack.app"),
            configuration: NSWorkspace.OpenConfiguration(),
            completionHandler: nil
        )
    }

    @objc
    private func handleOpenAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    @objc
    private func handleQuit() {
        NSApplication.shared.terminate(nil)
    }
}

private enum SlackUnreadResult {
    case count(Int)
    case slackNotRunning
    case permissionRequired
    case unavailable
}

private struct SlackUnreadProvider {
    func fetchUnreadCount() -> SlackUnreadResult {
        guard NSWorkspace.shared.runningApplications.contains(where: { $0.bundleIdentifier == "com.tinyspeck.slackmacgap" }) else {
            return .slackNotRunning
        }

        let script = """
        tell application "System Events"
            if UI elements enabled is false then
                return "__PERMISSION__"
            end if

            tell process "Dock"
                try
                    set dockItems to UI elements of list 1
                on error
                    return "__UNAVAILABLE__"
                end try

                repeat with dockItem in dockItems
                    try
                        set itemName to name of dockItem
                        if itemName is "Slack" or itemName contains "Slack" then
                            try
                                set badgeValue to value of attribute "AXStatusLabel" of dockItem
                            on error
                                set badgeValue to ""
                            end try

                            if badgeValue is missing value then
                                return ""
                            end if

                            return badgeValue as text
                        end if
                    end try
                end repeat
            end tell
        end tell

        return "__UNAVAILABLE__"
        """

        guard let appleScript = NSAppleScript(source: script) else {
            return .unavailable
        }

        var error: NSDictionary?
        let descriptor = appleScript.executeAndReturnError(&error)

        if let error {
            let message = (error[NSAppleScript.errorMessage] as? String) ?? ""
            if message.localizedCaseInsensitiveContains("not authorized") {
                return .permissionRequired
            }
            return .unavailable
        }

        let rawValue = descriptor.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        switch rawValue {
        case "__PERMISSION__":
            return .permissionRequired
        case "__UNAVAILABLE__":
            return .unavailable
        case "":
            return .count(0)
        default:
            let digits = rawValue.filter(\.isNumber)
            return .count(Int(digits) ?? 0)
        }
    }
}

@main
enum SlackMenuBadgeMain {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = SlackMenuBadgeApp()
        app.delegate = delegate
        app.run()
    }
}
