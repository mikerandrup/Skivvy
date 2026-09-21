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
        guard let app = NSWorkspace.shared.frontmostApplication
        else {
            logger.info("No frontmost application")
            return
        }
        let axApp = AXElement.application(pid: app.processIdentifier)
        axApp.setMessagingTimeout(1)
        guard let window = AXWindow.focused(in: axApp),
              let axFrame = window.frame
        else {
            logger.info("No usable window in \(app.localizedName ?? "app", privacy: .public)")
            return
        }
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

    static func describe(_ rect: CGRect?) -> String {
        guard let rect else { return "none" }
        return "\(Int(rect.minX)),\(Int(rect.minY)) \(Int(rect.width))x\(Int(rect.height))"
    }
}
