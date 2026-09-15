import AppKit
import SkivvyCore
import os

final class WindowController {
    private let permission: AccessibilityPermission
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
            layout, window: current, screens: screens
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
        logger.info(
            "\(layout.name, privacy: .public) on screen \(target.screen.id) matched=\(outcome.matched)"
        )
    }
}
