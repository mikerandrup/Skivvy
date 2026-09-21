import AppKit

extension ScreenInfo {
    /// Live snapshot of every display in NSScreen space.
    /// Read fresh for every operation; visibleFrame changes
    /// with menu bar auto-hide and Dock position. The id is
    /// the display id, so a placement record survives a
    /// change in screen order.
    @MainActor
    public static func current() -> [ScreenInfo] {
        NSScreen.screens.enumerated().map { index, screen in
            ScreenInfo(
                id: screen.displayID ?? index,
                frame: screen.frame,
                visibleFrame: screen.visibleFrame
            )
        }
    }

    /// Height of the primary screen, the only anchor used to
    /// flip between NSScreen space and AX space.
    @MainActor
    public static var primaryHeight: CGFloat {
        NSScreen.screens.first?.frame.maxY ?? 0
    }
}

extension NSScreen {
    static let screenNumberKey = NSDeviceDescriptionKey("NSScreenNumber")

    var displayID: Int? {
        (deviceDescription[Self.screenNumberKey] as? NSNumber)?.intValue
    }
}
