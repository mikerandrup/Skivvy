import AppKit
import ApplicationServices
import CoreGraphics
import Testing
@testable import SkivvyCore

/// Drives a real TextEdit window through every layout. Runs
/// only when the process running the tests has the
/// Accessibility grant, so it self-skips in untrusted
/// terminals and in CI.
@Suite(
    "Accessibility integration",
    .serialized,
    .enabled(if: AXIsProcessTrusted())
)
@MainActor
struct AccessibilityIntegrationTests {
    @Test(
        "Every layout lands on the frame it asked for",
        .timeLimit(.minutes(2))
    )
    func allLayouts() async throws {
        let helper = try await TextEditHelper.launch()
        defer { helper.terminate() }
        let window = try #require(helper.window)
        let primaryHeight = ScreenInfo.primaryHeight
        let screens = ScreenInfo.current()
        let axFrame = try #require(window.frame)
        let start = Geometry.flip(axFrame, primaryHeight: primaryHeight)
        let screen = try #require(
            Screens.containing(start, in: screens)
        )
        let bounds = Geometry.flip(
            screen.visibleFrame, primaryHeight: primaryHeight
        )
        for layout in Layout.allCases {
            let target = Geometry.flip(
                layout.frame(in: screen.visibleFrame),
                primaryHeight: primaryHeight
            )
            let outcome = WindowMover.apply(
                target, within: bounds, to: window
            )
            #expect(
                outcome.matched,
                "\(layout.name) got \(String(describing: outcome.achieved))"
            )
            let cgBounds = try #require(
                helper.cgBounds(matching: target)
            )
            #expect(Geometry.nearlyEqual(
                cgBounds, target, tolerance: Resolver.tolerance
            ))
        }
    }

    @Test(
        "Repeating a layout walks to the next screen",
        .timeLimit(.minutes(1))
    )
    func cycles() async throws {
        let screens = ScreenInfo.current()
        try #require(
            screens.count > 1,
            "needs two displays"
        )
        let helper = try await TextEditHelper.launch()
        defer { helper.terminate() }
        let window = try #require(helper.window)
        let primaryHeight = ScreenInfo.primaryHeight
        var frame = Geometry.flip(
            try #require(window.frame), primaryHeight: primaryHeight
        )
        let first = try #require(
            Resolver.resolve(.left, window: frame, screens: screens)
        )
        _ = WindowMover.apply(
            Geometry.flip(first.frame, primaryHeight: primaryHeight),
            to: window
        )
        frame = Geometry.flip(
            try #require(window.frame), primaryHeight: primaryHeight
        )
        let second = try #require(
            Resolver.resolve(.left, window: frame, screens: screens)
        )
        #expect(second.screen != first.screen)
    }
}

/// Launches TextEdit with a fresh untitled document and
/// exposes its first window through Accessibility.
@MainActor
final class TextEditHelper {
    let app: NSRunningApplication
    let axApp: AXElement
    let ownedLaunch: Bool

    static let bundleID = "com.apple.TextEdit"

    private init(app: NSRunningApplication, ownedLaunch: Bool) {
        self.app = app
        self.ownedLaunch = ownedLaunch
        axApp = AXElement.application(pid: app.processIdentifier)
        axApp.setMessagingTimeout(2)
    }

    static func launch() async throws -> TextEditHelper {
        let running = NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleID)
            .first
        let url = URL(fileURLWithPath: "/System/Applications/TextEdit.app")
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        config.createsNewApplicationInstance = false
        let app = try await NSWorkspace.shared.openApplication(
            at: url, configuration: config
        )
        let helper = TextEditHelper(
            app: app, ownedLaunch: running == nil
        )
        try await helper.waitForWindow()
        return helper
    }

    var window: AXWindow? {
        AXWindow.focused(in: axApp)
    }

    func waitForWindow() async throws {
        for _ in 0..<40 {
            if window?.frame != nil { return }
            try await Task.sleep(for: .milliseconds(250))
        }
        Issue.record("TextEdit never showed a window")
    }

    func cgBounds(matching target: CGRect) -> CGRect? {
        let options: CGWindowListOption = [.optionOnScreenOnly]
        let list = CGWindowListCopyWindowInfo(options, kCGNullWindowID)
            as? [[String: Any]] ?? []
        let pid = app.processIdentifier
        let mine = list.filter {
            ($0[kCGWindowOwnerPID as String] as? pid_t) == pid
        }
        let rects: [CGRect] = mine.compactMap {
            guard let b = $0[kCGWindowBounds as String]
                as? [String: CGFloat],
                  let x = b["X"], let y = b["Y"],
                  let w = b["Width"], let h = b["Height"]
            else { return nil }
            return CGRect(x: x, y: y, width: w, height: h)
        }
        return rects.min {
            distance($0, target) < distance($1, target)
        }
    }

    func terminate() {
        if ownedLaunch {
            app.terminate()
        }
    }

    private func distance(_ a: CGRect, _ b: CGRect) -> CGFloat {
        abs(a.minX - b.minX) + abs(a.minY - b.minY)
            + abs(a.width - b.width) + abs(a.height - b.height)
    }
}
