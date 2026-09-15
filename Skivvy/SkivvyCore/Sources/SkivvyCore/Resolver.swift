import CoreGraphics

public enum Resolver {
    public static let tolerance: CGFloat = 4

    public struct Target: Equatable, Sendable {
        public let screen: ScreenInfo
        public let frame: CGRect
    }

    /// Chooses where a window goes for a layout. If the window
    /// already occupies the layout on its own screen, the same
    /// layout on the next screen is chosen instead. That is
    /// Divvy's "cycle between screens when using shortcuts".
    public static func resolve(
        _ layout: Layout,
        window: CGRect,
        screens: [ScreenInfo]
    ) -> Target? {
        guard let current = Screens.containing(window, in: screens)
        else { return nil }
        let here = layout.frame(in: current.visibleFrame)
        let alreadyThere = Geometry.nearlyEqual(
            window, here, tolerance: tolerance
        )
        guard alreadyThere else {
            return Target(screen: current, frame: here)
        }
        let next = Screens.next(after: current, in: screens)
        let there = layout.frame(in: next.visibleFrame)
        return Target(screen: next, frame: there)
    }
}
