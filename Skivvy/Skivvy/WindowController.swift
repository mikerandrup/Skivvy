import AppKit
import SkivvyCore
import os

final class WindowController {
    private let permission: AccessibilityPermission
    private var lastPlacement: Placement?
    private let logger = Logger(
        subsystem: "com.metroplexweb.Skivvy", category: "window"
    )

    init(permission: AccessibilityPermission) {
        self.permission = permission
    }

    func apply(_ layout: Layout) {
        permission.refresh()
        guard permission.isTrusted else {
            permission.requestIfNeeded()
            return
        }
        guard let front = NSWorkspace.shared.frontmostApplication
        else {
            logger.info("No frontmost application")
            return
        }
        guard let found = target(front: front),
              let axFrame = found.window.frame
        else {
            logNoWindow(front: front)
            return
        }
        let (app, window) = (found.app, found.window)
        let primaryHeight = ScreenInfo.primaryHeight
        let screens = ScreenInfo.current()
        let current = Geometry.flip(axFrame, primaryHeight: primaryHeight)
        guard let target = Resolver.resolve(
            layout,
            window: current,
            element: window.element,
            screens: screens,
            previous: lastPlacement
        ) else {
            logger.info("No screens")
            return
        }
        let axTarget = Geometry.flip(
            target.frame, primaryHeight: primaryHeight
        )
        let axBounds = Geometry.flip(
            target.screen.visibleFrame, primaryHeight: primaryHeight
        )
        let workspace = NSWorkspace.shared
        let suppress = !(workspace.isVoiceOverEnabled
            || workspace.isSwitchControlEnabled)
        let outcome = WindowMover.apply(
            axTarget,
            within: axBounds,
            to: window,
            suppressEnhancedUI: suppress
        )
        let achieved = outcome.achieved.map {
            Geometry.flip($0, primaryHeight: primaryHeight)
        }
        lastPlacement = Placement(
            window: window.element,
            layout: layout,
            screenID: target.screen.id,
            requested: target.frame,
            achieved: achieved
        )
        let bundleID = app.bundleIdentifier ?? "?"
        let errors = outcome.axErrors
            .map { String($0.rawValue) }
            .joined(separator: ",")
        logger.info(
            "\(layout.name, privacy: .public) \(bundleID, privacy: .public) decision=\(target.decision.rawValue, privacy: .public) screen=\(target.screen.id) requested=\(Self.describe(target.frame), privacy: .public) achieved=\(Self.describe(achieved), privacy: .public) matched=\(outcome.matched) axErrors=\(errors, privacy: .public)"
        )
    }

    /// The frontmost app's window. A Chrome web app shim can stay
    /// frontmost while owning no windows, so when the frontmost
    /// app has none, fall back to the app Accessibility reports
    /// as focused.
    private func target(
        front: NSRunningApplication
    ) -> (app: NSRunningApplication, window: AXWindow)? {
        if let window = Self.window(of: front) {
            return (front, window)
        }
        let system = AXElement.systemWide
        guard let focused = system.element(
                AXAttribute.focusedApplication
              ),
              let pid = focused.pid,
              pid != front.processIdentifier,
              let app = NSRunningApplication(processIdentifier: pid),
              let window = Self.window(of: app)
        else { return nil }
        logger.info("No usable window in \(front.localizedName ?? "app", privacy: .public); using focused \(app.localizedName ?? "app", privacy: .public)")
        return (app, window)
    }

    private static func window(
        of app: NSRunningApplication
    ) -> AXWindow? {
        let axApp = AXElement.application(pid: app.processIdentifier)
        axApp.setMessagingTimeout(1)
        guard let window = AXWindow.focused(in: axApp),
              window.frame != nil
        else { return nil }
        return window
    }

    /// Logs the raw AXError for each window lookup and the state
    /// of whatever window was found, so a failure names its cause.
    private func logNoWindow(front: NSRunningApplication) {
        let axApp = AXElement.application(pid: front.processIdentifier)
        axApp.setMessagingTimeout(1)
        let lookups = [
            AXAttribute.focusedWindow,
            AXAttribute.mainWindow,
            AXAttribute.windows,
        ].map { "\($0)=\(axApp.error(reading: $0).rawValue)" }
        let windowCount = axApp.elements(AXAttribute.windows).count
        let system = AXElement.systemWide
        let systemFocus = system.error(
            reading: AXAttribute.focusedApplication
        ).rawValue
        let systemPid = system.element(
            AXAttribute.focusedApplication
        )?.pid.map(String.init) ?? "none"
        var state = "none"
        if let w = axApp.element(AXAttribute.focusedWindow)
            ?? axApp.element(AXAttribute.mainWindow) {
            let min = w.bool(AXAttribute.minimized)
                .map(String.init) ?? "?"
            let full = w.bool(AXAttribute.fullScreen)
                .map(String.init) ?? "?"
            let sub = w.string(AXAttribute.subrole) ?? "?"
            let pos = w.error(reading: AXAttribute.position).rawValue
            let size = w.error(reading: AXAttribute.size).rawValue
            state = "subrole=\(sub) minimized=\(min) fullScreen=\(full) positionErr=\(pos) sizeErr=\(size)"
        }
        logger.info(
            "No usable window in \(front.localizedName ?? "app", privacy: .public) pid=\(front.processIdentifier) trusted=\(self.permission.isTrusted) \(lookups.joined(separator: " "), privacy: .public) windows=\(windowCount) systemFocusedAppErr=\(systemFocus) systemFocusedPid=\(systemPid, privacy: .public) window=[\(state, privacy: .public)]"
        )
    }

    static func describe(_ rect: CGRect?) -> String {
        guard let rect else { return "none" }
        return "\(Int(rect.minX)),\(Int(rect.minY)) \(Int(rect.width))x\(Int(rect.height))"
    }
}
