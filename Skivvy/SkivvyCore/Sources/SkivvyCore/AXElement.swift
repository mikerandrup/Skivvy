import ApplicationServices
import CoreGraphics

/// Thin wrapper over AXUIElement with typed accessors.
public struct AXElement: @unchecked Sendable {
    public let raw: AXUIElement

    public init(_ raw: AXUIElement) {
        self.raw = raw
    }

    public static func application(pid: pid_t) -> AXElement {
        AXElement(AXUIElementCreateApplication(pid))
    }

    public static let systemWide = AXElement(
        AXUIElementCreateSystemWide()
    )

    public func setMessagingTimeout(_ seconds: Float) {
        AXUIElementSetMessagingTimeout(raw, seconds)
    }

    /// True when both refer to the same UI element. AXUIElement
    /// supports CFEqual, so no private window id is needed.
    public func isSame(as other: AXElement) -> Bool {
        CFEqual(raw, other.raw)
    }

    public var pid: pid_t? {
        var pid: pid_t = 0
        let err = AXUIElementGetPid(raw, &pid)
        return err == .success ? pid : nil
    }

    public func value(_ attribute: String) -> CFTypeRef? {
        var out: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(
            raw, attribute as CFString, &out
        )
        return err == .success ? out : nil
    }

    /// The raw result of reading an attribute, for diagnostics.
    public func error(reading attribute: String) -> AXError {
        var out: CFTypeRef?
        return AXUIElementCopyAttributeValue(
            raw, attribute as CFString, &out
        )
    }

    public func element(_ attribute: String) -> AXElement? {
        guard let v = value(attribute),
              CFGetTypeID(v) == AXUIElementGetTypeID()
        else { return nil }
        return AXElement(v as! AXUIElement)
    }

    public func elements(_ attribute: String) -> [AXElement] {
        guard let v = value(attribute) as? [AXUIElement]
        else { return [] }
        return v.map(AXElement.init)
    }

    public func string(_ attribute: String) -> String? {
        value(attribute) as? String
    }

    public func bool(_ attribute: String) -> Bool? {
        value(attribute) as? Bool
    }

    public func point(_ attribute: String) -> CGPoint? {
        guard let v = value(attribute),
              CFGetTypeID(v) == AXValueGetTypeID()
        else { return nil }
        var p = CGPoint.zero
        return AXValueGetValue(v as! AXValue, .cgPoint, &p) ? p : nil
    }

    public func size(_ attribute: String) -> CGSize? {
        guard let v = value(attribute),
              CFGetTypeID(v) == AXValueGetTypeID()
        else { return nil }
        var s = CGSize.zero
        return AXValueGetValue(v as! AXValue, .cgSize, &s) ? s : nil
    }

    @discardableResult
    public func set(_ attribute: String, point: CGPoint) -> AXError {
        var p = point
        guard let v = AXValueCreate(.cgPoint, &p)
        else { return .failure }
        return AXUIElementSetAttributeValue(
            raw, attribute as CFString, v
        )
    }

    @discardableResult
    public func set(_ attribute: String, size: CGSize) -> AXError {
        var s = size
        guard let v = AXValueCreate(.cgSize, &s)
        else { return .failure }
        return AXUIElementSetAttributeValue(
            raw, attribute as CFString, v
        )
    }

    @discardableResult
    public func set(_ attribute: String, bool: Bool) -> AXError {
        AXUIElementSetAttributeValue(
            raw, attribute as CFString, bool as CFBoolean
        )
    }

    public func isSettable(_ attribute: String) -> Bool {
        var settable = DarwinBoolean(false)
        let err = AXUIElementIsAttributeSettable(
            raw, attribute as CFString, &settable
        )
        return err == .success ? settable.boolValue : true
    }
}

public enum AXAttribute {
    public static let focusedApplication =
        kAXFocusedApplicationAttribute
    public static let focusedWindow = kAXFocusedWindowAttribute
    public static let mainWindow = kAXMainWindowAttribute
    public static let windows = kAXWindowsAttribute
    public static let position = kAXPositionAttribute
    public static let size = kAXSizeAttribute
    public static let subrole = kAXSubroleAttribute
    public static let parent = kAXParentAttribute
    public static let minimized = kAXMinimizedAttribute
    public static let fullScreen = "AXFullScreen"
    public static let enhancedUserInterface = "AXEnhancedUserInterface"
}
