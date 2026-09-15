import CoreGraphics
import Testing
@testable import SkivvyCore

@Suite("Coordinate flip")
struct GeometryTests {
    let primaryHeight: CGFloat = 1080

    @Test("Flip is its own inverse")
    func selfInverse() {
        let r = CGRect(x: 100, y: 200, width: 300, height: 400)
        let once = Geometry.flip(r, primaryHeight: primaryHeight)
        let twice = Geometry.flip(once, primaryHeight: primaryHeight)
        #expect(twice == r)
    }

    @Test("Top-left of the primary maps to origin")
    func primaryTopLeft() {
        let r = CGRect(x: 0, y: 1080 - 50, width: 10, height: 50)
        let ax = Geometry.flip(r, primaryHeight: primaryHeight)
        #expect(ax == CGRect(x: 0, y: 0, width: 10, height: 50))
    }

    @Test("A screen above the primary has negative AX y")
    func screenAbove() {
        // NSScreen: secondary sits above, y from 1080 to 2160.
        let window = CGRect(
            x: 0, y: 1080 + 500, width: 200, height: 100
        )
        let ax = Geometry.flip(window, primaryHeight: primaryHeight)
        let expected: CGFloat = -600
        #expect(ax.minY == expected)
        #expect(ax.minX == 0)
    }

    @Test("A screen to the left keeps negative x")
    func screenLeft() {
        let window = CGRect(
            x: -1920, y: 0, width: 200, height: 100
        )
        let ax = Geometry.flip(window, primaryHeight: primaryHeight)
        #expect(ax.minX == -1920)
        let expected: CGFloat = 980
        #expect(ax.minY == expected)
    }

    @Test("Nearly equal honors tolerance on every edge")
    func nearly() {
        let a = CGRect(x: 0, y: 0, width: 100, height: 100)
        let b = CGRect(x: 2, y: -2, width: 96, height: 104)
        #expect(Geometry.nearlyEqual(a, b, tolerance: 4))
        #expect(!Geometry.nearlyEqual(a, b, tolerance: 1))
        let c = CGRect(x: 0, y: 0, width: 110, height: 100)
        #expect(!Geometry.nearlyEqual(a, c, tolerance: 4))
    }
}
