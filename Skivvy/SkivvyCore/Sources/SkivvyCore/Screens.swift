import CoreGraphics

public struct ScreenInfo: Hashable, Sendable {
    public let id: Int
    public let frame: CGRect
    public let visibleFrame: CGRect

    public init(id: Int, frame: CGRect, visibleFrame: CGRect) {
        self.id = id
        self.frame = frame
        self.visibleFrame = visibleFrame
    }
}

public enum Screens {
    /// Left to right, then top to bottom.
    public static func ordered(
        _ screens: [ScreenInfo]
    ) -> [ScreenInfo] {
        screens.sorted { a, b in
            if a.frame.minX != b.frame.minX {
                return a.frame.minX < b.frame.minX
            }
            return a.frame.maxY > b.frame.maxY
        }
    }

    public static func containing(
        _ window: CGRect, in screens: [ScreenInfo]
    ) -> ScreenInfo? {
        let center = CGPoint(x: window.midX, y: window.midY)
        if let hit = screens.first(
            where: { $0.frame.contains(center) }
        ) {
            return hit
        }
        let byOverlap = screens.max { a, b in
            overlapArea(window, a.frame)
                < overlapArea(window, b.frame)
        }
        if let best = byOverlap,
           overlapArea(window, best.frame) > 0 {
            return best
        }
        return screens.first
    }

    public static func next(
        after screen: ScreenInfo, in screens: [ScreenInfo]
    ) -> ScreenInfo {
        let sorted = ordered(screens)
        guard let index = sorted.firstIndex(of: screen),
              sorted.count > 1
        else { return screen }
        return sorted[(index + 1) % sorted.count]
    }

    static func overlapArea(_ a: CGRect, _ b: CGRect) -> CGFloat {
        let r = a.intersection(b)
        return r.isNull ? 0 : r.width * r.height
    }
}
