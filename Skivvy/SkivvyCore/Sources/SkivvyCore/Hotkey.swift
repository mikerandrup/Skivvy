public struct Hotkey: Hashable, Sendable {
    public enum Modifier: Hashable, Sendable {
        case command, option, shift
    }

    public static let leftArrow: UInt32 = 123
    public static let rightArrow: UInt32 = 124
    public static let upArrow: UInt32 = 126

    public let keyCode: UInt32
    public let modifiers: Set<Modifier>

    public init(keyCode: UInt32, modifiers: Set<Modifier>) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }
}

extension Layout {
    public var hotkey: Hotkey {
        Hotkey(keyCode: keyCode, modifiers: modifiers)
    }

    var keyCode: UInt32 {
        switch self {
        case .left, .farLeft, .hogLeft: Hotkey.leftArrow
        case .right, .farRight, .hogRight: Hotkey.rightArrow
        case .full, .middle, .hogMiddle: Hotkey.upArrow
        }
    }

    var modifiers: Set<Hotkey.Modifier> {
        switch self {
        case .left, .right, .full: [.command]
        case .farLeft, .farRight, .middle: [.command, .option]
        case .hogLeft, .hogRight, .hogMiddle: [.command, .shift]
        }
    }
}

extension Hotkey {
    /// Menu-style rendering such as "⌥⌘←", modifiers in the
    /// order macOS shows them.
    public var symbols: String {
        var out = ""
        if modifiers.contains(.option) { out += "⌥" }
        if modifiers.contains(.shift) { out += "⇧" }
        if modifiers.contains(.command) { out += "⌘" }
        switch keyCode {
        case Self.leftArrow: out += "←"
        case Self.rightArrow: out += "→"
        case Self.upArrow: out += "↑"
        default: break
        }
        return out
    }
}
