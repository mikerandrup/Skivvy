import CoreGraphics

/// What Skivvy last did to a window. Lets a repeat press cycle
/// even when the app could not take the exact layout frame.
public struct Placement: Sendable {
    public let window: AXElement
    public let layout: Layout
    public let screenID: Int
    public let requested: CGRect
    public let achieved: CGRect?

    public init(
        window: AXElement,
        layout: Layout,
        screenID: Int,
        requested: CGRect,
        achieved: CGRect?
    ) {
        self.window = window
        self.layout = layout
        self.screenID = screenID
        self.requested = requested
        self.achieved = achieved
    }
}

public enum Resolver {
    public static let tolerance: CGFloat = 4

    public enum Decision: String, Sendable {
        case first
        case cycleRecord
        case cycleIdeal
    }

    public struct Target: Equatable, Sendable {
        public let screen: ScreenInfo
        public let frame: CGRect
        public let decision: Decision
    }

    /// Chooses where a window goes for a layout. A repeat press
    /// walks the window to the same layout on the next screen.
    /// "Repeat" means either the window is still where the last
    /// placement left it (even if the app clamped that frame),
    /// or it already sits on the ideal frame for this layout.
    /// That is Divvy's "cycle between screens when using
    /// shortcuts".
    public static func resolve(
        _ layout: Layout,
        window: CGRect,
        element: AXElement? = nil,
        screens: [ScreenInfo],
        previous: Placement? = nil
    ) -> Target? {
        guard let current = Screens.containing(window, in: screens)
        else { return nil }
        if let recorded = recordedScreen(
            for: layout, window: window, element: element,
            screens: screens, previous: previous
        ) {
            let next = Screens.next(after: recorded, in: screens)
            return Target(
                screen: next,
                frame: layout.frame(in: next.visibleFrame),
                decision: .cycleRecord
            )
        }
        let here = layout.frame(in: current.visibleFrame)
        let alreadyThere = Geometry.nearlyEqual(
            window, here, tolerance: tolerance
        )
        guard alreadyThere else {
            return Target(screen: current, frame: here, decision: .first)
        }
        let next = Screens.next(after: current, in: screens)
        return Target(
            screen: next,
            frame: layout.frame(in: next.visibleFrame),
            decision: .cycleIdeal
        )
    }

    /// The screen the last placement targeted, when that
    /// placement was for this layout and this window and the
    /// window has not moved since.
    static func recordedScreen(
        for layout: Layout,
        window: CGRect,
        element: AXElement?,
        screens: [ScreenInfo],
        previous: Placement?
    ) -> ScreenInfo? {
        guard let previous, let element,
              previous.layout == layout,
              previous.window.isSame(as: element),
              let screen = screens.first(
                  where: { $0.id == previous.screenID }
              )
        else { return nil }
        let stillThere = matches(window, previous.achieved)
            || matches(window, previous.requested)
        return stillThere ? screen : nil
    }

    static func matches(_ a: CGRect, _ b: CGRect?) -> Bool {
        guard let b else { return false }
        return Geometry.nearlyEqual(a, b, tolerance: tolerance)
    }
}
