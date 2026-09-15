import AppKit

extension ScreenInfo {
    /// Live snapshot of every display in NSScreen space.
    /// Read fresh for every operation; visibleFrame changes
    /// with menu bar auto-hide and Dock position.
    @MainActor
    public static func current() -> [ScreenInfo] {
        NSScreen.screens.enumerated().map { index, screen in
            ScreenInfo(
                id: index,
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
