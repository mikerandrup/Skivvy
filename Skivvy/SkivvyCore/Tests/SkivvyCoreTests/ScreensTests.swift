import CoreGraphics
import Testing
@testable import SkivvyCore

@Suite("Screens and cycling")
struct ScreensTests {
    let primary = ScreenInfo(
        id: 1,
        frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
        visibleFrame: CGRect(
            x: 0, y: 0, width: 1920, height: 1050
        )
    )
    let rightSide = ScreenInfo(
        id: 2,
        frame: CGRect(x: 1920, y: 0, width: 2560, height: 1440),
        visibleFrame: CGRect(
            x: 1920, y: 0, width: 2560, height: 1410
        )
    )
    let leftSide = ScreenInfo(
        id: 3,
        frame: CGRect(x: -1440, y: 0, width: 1440, height: 900),
        visibleFrame: CGRect(
            x: -1440, y: 0, width: 1440, height: 862.5
        )
    )
    let above = ScreenInfo(
        id: 4,
        frame: CGRect(x: 0, y: 1080, width: 1920, height: 1080),
        visibleFrame: CGRect(
            x: 0, y: 1080, width: 1920, height: 1050
        )
    )

    @Test("Ordered left to right then top to bottom")
    func ordering() {
        let ids = Screens.ordered(
            [primary, rightSide, leftSide, above]
        ).map(\.id)
        #expect(ids == [3, 4, 1, 2])
    }

    @Test("Containing picks by window center")
    func containing() {
        let w = CGRect(x: 1800, y: 100, width: 400, height: 300)
        let hit = Screens.containing(w, in: [primary, rightSide])
        #expect(hit?.id == 2)
    }

    @Test("Containing falls back to largest overlap")
    func overlapFallback() {
        // Center lands in a gap between two screens.
        let gapRight = ScreenInfo(
            id: 5,
            frame: CGRect(x: 2000, y: 0, width: 1000, height: 1000),
            visibleFrame: CGRect(
                x: 2000, y: 0, width: 1000, height: 970
            )
        )
        let w = CGRect(x: 1900, y: 0, width: 140, height: 100)
        let hit = Screens.containing(w, in: [primary, gapRight])
        #expect(hit?.id == 2 || hit?.id == 5)
        let mostlyPrimary = CGRect(
            x: 1850, y: 0, width: 200, height: 100
        )
        #expect(
            Screens.containing(mostlyPrimary, in: [primary, gapRight])?
                .id == 1
        )
    }

    @Test("Containing with no overlap returns the first screen")
    func nothingOverlaps() {
        let w = CGRect(x: 9000, y: 9000, width: 10, height: 10)
        #expect(Screens.containing(w, in: [primary])?.id == 1)
        #expect(Screens.containing(w, in: []) == nil)
    }

    @Test("Next wraps around")
    func nextWraps() {
        let all = [primary, rightSide, leftSide]
        #expect(Screens.next(after: leftSide, in: all).id == 1)
        #expect(Screens.next(after: primary, in: all).id == 2)
        #expect(Screens.next(after: rightSide, in: all).id == 3)
    }

    @Test("Next of a single screen is itself")
    func nextSingle() {
        #expect(Screens.next(after: primary, in: [primary]).id == 1)
    }

    @Test("First press lands on the current screen")
    func firstPress() {
        let w = CGRect(x: 2500, y: 200, width: 800, height: 600)
        let t = Resolver.resolve(
            .left, window: w, screens: [primary, rightSide]
        )
        #expect(t?.screen.id == 2)
        #expect(t?.frame
            == Layout.left.frame(in: rightSide.visibleFrame))
    }

    @Test("Repeated press walks to the next screen")
    func repeatedPress() {
        let inPlace = Layout.left.frame(in: rightSide.visibleFrame)
        let t = Resolver.resolve(
            .left, window: inPlace, screens: [primary, rightSide]
        )
        #expect(t?.screen.id == 1)
        #expect(t?.frame
            == Layout.left.frame(in: primary.visibleFrame))
    }

    @Test("Repeated press on one screen stays put")
    func repeatedSingle() {
        let inPlace = Layout.full.frame(in: primary.visibleFrame)
        let t = Resolver.resolve(
            .full, window: inPlace, screens: [primary]
        )
        #expect(t?.screen.id == 1)
        #expect(t?.frame == inPlace)
    }

    @Test("A window slightly off target still counts as placed")
    func tolerance() {
        var w = Layout.farLeft.frame(in: primary.visibleFrame)
        w.size.width -= 2
        w.origin.y += 1
        let t = Resolver.resolve(
            .farLeft, window: w, screens: [primary, rightSide]
        )
        #expect(t?.screen.id == 2)
    }

    @Test("A different layout on the same origin does not cycle")
    func differentLayoutSameOrigin() {
        let hog = Layout.hogLeft.frame(in: primary.visibleFrame)
        let t = Resolver.resolve(
            .left, window: hog, screens: [primary, rightSide]
        )
        #expect(t?.screen.id == 1)
        #expect(t?.frame
            == Layout.left.frame(in: primary.visibleFrame))
    }

    @Test("Each screen gets its own visible height")
    func perScreenHeight() {
        let a = Layout.full.frame(in: leftSide.visibleFrame)
        let b = Layout.full.frame(in: rightSide.visibleFrame)
        #expect(a.height == 862.5)
        #expect(b.height == 1410)
    }

    @Test("Resolve with no screens is nil")
    func noScreens() {
        let w = CGRect(x: 0, y: 0, width: 10, height: 10)
        #expect(Resolver.resolve(.left, window: w, screens: []) == nil)
    }
}
