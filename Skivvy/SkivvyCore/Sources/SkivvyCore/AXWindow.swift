import ApplicationServices
import CoreGraphics

/// A window of another application, addressed through the
/// Accessibility API. Frames are in AX space (top-left origin).
public struct AXWindow: @unchecked Sendable {
    public let element: AXElement
    public let application: AXElement

    public init(element: AXElement, application: AXElement) {
        self.element = element
        self.application = application
    }

    /// The window a hotkey should act on, or nil when the app
    /// has no usable window. Sheets resolve to their parent.
    /// Minimized and fullscreen windows are skipped.
    public static func focused(in app: AXElement) -> AXWindow? {
        let candidate = app.element(AXAttribute.focusedWindow)
            ?? app.element(AXAttribute.mainWindow)
            ?? app.elements(AXAttribute.windows).first
        guard var window = candidate else { return nil }
        if let subrole = window.string(AXAttribute.subrole),
           subrole == "AXSheet" || subrole == "AXSystemDialog",
           let parent = window.element(AXAttribute.parent) {
            window = parent
        }
        if window.bool(AXAttribute.minimized) == true {
            return nil
        }
        if window.bool(AXAttribute.fullScreen) == true {
            return nil
        }
        return AXWindow(element: window, application: app)
    }

    public var frame: CGRect? {
        guard let p = element.point(AXAttribute.position),
              let s = element.size(AXAttribute.size)
        else { return nil }
        return CGRect(origin: p, size: s)
    }

    public var isResizable: Bool {
        element.isSettable(AXAttribute.size)
    }
}
