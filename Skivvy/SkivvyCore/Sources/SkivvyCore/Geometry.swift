import CoreGraphics

public enum Geometry {
    /// Converts between NSScreen space (origin bottom-left)
    /// and Accessibility space (origin top-left). The flip is
    /// anchored to the primary screen height only, so it is
    /// correct for every screen in a multi-display layout and
    /// is its own inverse.
    public static func flip(
        _ rect: CGRect, primaryHeight: CGFloat
    ) -> CGRect {
        CGRect(
            x: rect.minX,
            y: primaryHeight - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    public static func nearlyEqual(
        _ a: CGRect, _ b: CGRect, tolerance: CGFloat
    ) -> Bool {
        abs(a.minX - b.minX) <= tolerance
            && abs(a.minY - b.minY) <= tolerance
            && abs(a.maxX - b.maxX) <= tolerance
            && abs(a.maxY - b.maxY) <= tolerance
    }
}
