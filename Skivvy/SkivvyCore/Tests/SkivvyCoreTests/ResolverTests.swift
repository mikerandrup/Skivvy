import ApplicationServices
import CoreGraphics
import Testing
@testable import SkivvyCore

@Suite("Placement record cycling")
struct ResolverTests {
    let primary = ScreenInfo(
        id: 1,
        frame: CGRect(x: 0, y: 0, width: 2560, height: 1080),
        visibleFrame: CGRect(
            x: 0, y: 0, width: 2560, height: 1050
        )
    )
    let small = ScreenInfo(
        id: 2,
        frame: CGRect(x: -679, y: -768, width: 1024, height: 768),
        visibleFrame: CGRect(
            x: -679, y: -768, width: 1024, height: 768
        )
    )
    // AXUIElement supports CFEqual; two elements for one pid
    // compare equal, different pids do not. No grant needed.
    let window = AXElement.application(pid: 1)
    let sameWindow = AXElement.application(pid: 1)
    let otherWindow = AXElement.application(pid: 2)

    var screens: [ScreenInfo] { [primary, small] }

    /// Far Right on the small screen asks for 341 wide; the app
    /// refused and kept 600.
    var clamped: Placement {
        let requested = Layout.farRight.frame(in: small.visibleFrame)
        var achieved = requested
        achieved.origin.x -= 259
        achieved.size.width = 600
        return Placement(
            window: window,
            layout: .farRight,
            screenID: small.id,
            requested: requested,
            achieved: achieved
        )
    }

    @Test("A clamped result still cycles on the next press")
    func clampedResultCycles() {
        let record = clamped
        let t = Resolver.resolve(
            .farRight,
            window: record.achieved!,
            element: sameWindow,
            screens: screens,
            previous: record
        )
        #expect(t?.decision == .cycleRecord)
        #expect(t?.screen.id == primary.id)
        #expect(t?.frame
            == Layout.farRight.frame(in: primary.visibleFrame))
    }

    @Test("Cycling continues from the recorded target screen")
    func cyclesFromRecordedScreen() {
        // The clamped window's center may sit on another screen;
        // the record, not the center, decides where to go next.
        let record = clamped
        var straddling = record.achieved!
        straddling.origin.x = primary.frame.minX - 200
        let t = Resolver.resolve(
            .farRight,
            window: straddling,
            element: window,
            screens: screens,
            previous: Placement(
                window: window,
                layout: .farRight,
                screenID: small.id,
                requested: record.requested,
                achieved: straddling
            )
        )
        #expect(t?.decision == .cycleRecord)
        #expect(t?.screen.id == primary.id)
    }

    @Test("A window the user moved after placement starts over")
    func movedByUser() {
        let record = clamped
        var moved = record.achieved!
        moved.origin.x += 40
        let t = Resolver.resolve(
            .farRight,
            window: moved,
            element: window,
            screens: screens,
            previous: record
        )
        #expect(t?.decision == .first)
        #expect(t?.screen.id == small.id)
    }

    @Test("A different layout ignores the record")
    func differentLayout() {
        let record = clamped
        let t = Resolver.resolve(
            .middle,
            window: record.achieved!,
            element: window,
            screens: screens,
            previous: record
        )
        #expect(t?.decision == .first)
        #expect(t?.screen.id == small.id)
    }

    @Test("A different window ignores the record")
    func differentWindow() {
        let record = clamped
        let t = Resolver.resolve(
            .farRight,
            window: record.achieved!,
            element: otherWindow,
            screens: screens,
            previous: record
        )
        #expect(t?.decision == .first)
        #expect(t?.screen.id == small.id)
    }

    @Test("A recorded screen that is gone falls back")
    func recordedScreenMissing() {
        let record = clamped
        let t = Resolver.resolve(
            .farRight,
            window: record.achieved!,
            element: window,
            screens: [primary],
            previous: record
        )
        #expect(t?.decision == .first)
        #expect(t?.screen.id == primary.id)
    }

    @Test("The requested frame also counts as still there")
    func requestedFrameMatches() {
        let record = clamped
        let t = Resolver.resolve(
            .farRight,
            window: record.requested,
            element: window,
            screens: screens,
            previous: record
        )
        #expect(t?.decision == .cycleRecord)
    }

    @Test("Without a record the ideal frame still cycles")
    func idealStillCycles() {
        let inPlace = Layout.farRight.frame(in: small.visibleFrame)
        let t = Resolver.resolve(
            .farRight,
            window: inPlace,
            element: window,
            screens: screens
        )
        #expect(t?.decision == .cycleIdeal)
        #expect(t?.screen.id == primary.id)
    }

    @Test("Element identity is CFEqual")
    func identity() {
        #expect(window.isSame(as: sameWindow))
        #expect(!window.isSame(as: otherWindow))
    }
}
