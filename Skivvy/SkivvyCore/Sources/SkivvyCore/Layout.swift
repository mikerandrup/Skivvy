import CoreGraphics

public enum Layout: CaseIterable, Sendable {
    case left, right, full
    case farLeft, farRight, middle
    case hogLeft, hogRight, hogMiddle

    public static let columnCount = 6

    public var columns: ClosedRange<Int> {
        switch self {
        case .left: 0...2
        case .right: 3...5
        case .full: 0...5
        case .farLeft: 0...1
        case .farRight: 4...5
        case .middle: 2...3
        case .hogLeft: 0...3
        case .hogRight: 2...5
        case .hogMiddle: 1...4
        }
    }

    public var name: String {
        switch self {
        case .left: "left"
        case .right: "right"
        case .full: "full"
        case .farLeft: "Far Left"
        case .farRight: "Far Right"
        case .middle: "Middle"
        case .hogLeft: "Hog Left"
        case .hogRight: "Hog Right"
        case .hogMiddle: "Hog Middle"
        }
    }

    public func frame(in visible: CGRect) -> CGRect {
        let startX = Self.edge(columns.lowerBound, in: visible)
        let endX = Self.edge(columns.upperBound + 1, in: visible)
        return CGRect(
            x: startX,
            y: visible.minY,
            width: endX - startX,
            height: visible.height
        )
    }

    static func edge(_ column: Int, in visible: CGRect) -> CGFloat {
        let fraction = CGFloat(column) / CGFloat(columnCount)
        return (visible.minX + visible.width * fraction).rounded()
    }
}
