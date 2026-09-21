import ApplicationServices
import CoreGraphics

public enum WindowMover {
    public struct Outcome: Sendable {
        public let requested: CGRect
        public let achieved: CGRect?
        /// Results of the size, position, size writes in order.
        public let axErrors: [AXError]
        public var matched: Bool {
            guard let achieved else { return false }
            return Geometry.nearlyEqual(
                requested, achieved, tolerance: Resolver.tolerance
            )
        }
    }

    /// Applies an AX-space frame. Size is written before and
    /// after the move because macOS clamps a window's size to
    /// the display it is currently on. Apps that animate through
    /// AXEnhancedUserInterface have it switched off for the
    /// duration of the write. `bounds` is the destination
    /// screen's visible frame in AX space; a window that refuses
    /// to shrink is kept inside it.
    public static func apply(
        _ target: CGRect,
        within bounds: CGRect? = nil,
        to window: AXWindow,
        suppressEnhancedUI: Bool = true
    ) -> Outcome {
        let app = window.application
        let hadEnhancedUI = suppressEnhancedUI
            && app.bool(AXAttribute.enhancedUserInterface) == true
        if hadEnhancedUI {
            app.set(AXAttribute.enhancedUserInterface, bool: false)
        }
        defer {
            if hadEnhancedUI {
                app.set(AXAttribute.enhancedUserInterface, bool: true)
            }
        }

        let el = window.element
        let resizable = window.isResizable
        var axErrors: [AXError] = []
        if resizable {
            axErrors.append(el.set(AXAttribute.size, size: target.size))
        }
        axErrors.append(el.set(AXAttribute.position, point: target.origin))
        if resizable {
            axErrors.append(el.set(AXAttribute.size, size: target.size))
        }

        var achieved = window.frame
        if let got = achieved,
           !Geometry.nearlyEqual(
               got, target, tolerance: Resolver.tolerance
           ) {
            // The app enforced a minimum. Keep the window on
            // the destination screen, anchored to the target.
            let limit = bounds ?? target
            let origin = CGPoint(
                x: max(limit.minX,
                       min(target.minX, limit.maxX - got.width)),
                y: max(limit.minY,
                       min(target.minY, limit.maxY - got.height))
            )
            el.set(AXAttribute.position, point: origin)
            achieved = window.frame
        }
        return Outcome(
            requested: target, achieved: achieved, axErrors: axErrors
        )
    }
}
