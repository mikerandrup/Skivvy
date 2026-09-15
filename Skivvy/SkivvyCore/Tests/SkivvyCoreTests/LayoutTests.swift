import CoreGraphics
import Testing
@testable import SkivvyCore

@Suite("Layout columns")
struct LayoutTests {
    let hd = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    let secondary = CGRect(
        x: 1920, y: 0, width: 2560, height: 1410
    )

    @Test("Column spans match the Divvy config")
    func spans() {
        #expect(Layout.left.columns == 0...2)
        #expect(Layout.right.columns == 3...5)
        #expect(Layout.full.columns == 0...5)
        #expect(Layout.farLeft.columns == 0...1)
        #expect(Layout.farRight.columns == 4...5)
        #expect(Layout.middle.columns == 2...3)
        #expect(Layout.hogLeft.columns == 0...3)
        #expect(Layout.hogRight.columns == 2...5)
        #expect(Layout.hogMiddle.columns == 1...4)
    }

    @Test("Nine layouts exist")
    func count() {
        #expect(Layout.allCases.count == 9)
    }

    @Test("Frames on a 1920x1080 screen")
    func hdFrames() {
        #expect(Layout.left.frame(in: hd)
            == CGRect(x: 0, y: 0, width: 960, height: 1080))
        #expect(Layout.right.frame(in: hd)
            == CGRect(x: 960, y: 0, width: 960, height: 1080))
        #expect(Layout.full.frame(in: hd) == hd)
        #expect(Layout.farLeft.frame(in: hd)
            == CGRect(x: 0, y: 0, width: 640, height: 1080))
        #expect(Layout.middle.frame(in: hd)
            == CGRect(x: 640, y: 0, width: 640, height: 1080))
        #expect(Layout.farRight.frame(in: hd)
            == CGRect(x: 1280, y: 0, width: 640, height: 1080))
        #expect(Layout.hogLeft.frame(in: hd)
            == CGRect(x: 0, y: 0, width: 1280, height: 1080))
        #expect(Layout.hogRight.frame(in: hd)
            == CGRect(x: 640, y: 0, width: 1280, height: 1080))
        #expect(Layout.hogMiddle.frame(in: hd)
            == CGRect(x: 320, y: 0, width: 1280, height: 1080))
    }

    @Test("Frames on an offset secondary screen")
    func offsetFrames() {
        let f = Layout.middle.frame(in: secondary)
        #expect(f.minX == 2773)
        #expect(f.maxX == 3627)
        #expect(f.width == 854)
        #expect(f.minY == 0)
        #expect(f.height == 1410)
    }

    @Test(
        "Every layout is full height",
        arguments: Layout.allCases
    )
    func fullHeight(_ layout: Layout) {
        let inset = CGRect(
            x: 0, y: 80, width: 1920, height: 970
        )
        let f = layout.frame(in: inset)
        #expect(f.minY == inset.minY)
        #expect(f.height == inset.height)
    }

    @Test("Edges are whole points")
    func wholePoints() {
        let odd = CGRect(x: 0, y: 0, width: 1001, height: 700)
        for layout in Layout.allCases {
            let f = layout.frame(in: odd)
            #expect(f.minX == f.minX.rounded())
            #expect(f.maxX == f.maxX.rounded())
        }
    }

    @Test("Halves and thirds tile without gaps")
    func tiling() {
        let l = Layout.left.frame(in: hd)
        let r = Layout.right.frame(in: hd)
        #expect(l.maxX == r.minX)
        let a = Layout.farLeft.frame(in: hd)
        let b = Layout.middle.frame(in: hd)
        let c = Layout.farRight.frame(in: hd)
        #expect(a.maxX == b.minX)
        #expect(b.maxX == c.minX)
        #expect(a.minX == hd.minX)
        #expect(c.maxX == hd.maxX)
    }

    @Test("Hog layouts overlap by the middle third")
    func hogOverlap() {
        let hl = Layout.hogLeft.frame(in: hd)
        let hr = Layout.hogRight.frame(in: hd)
        let mid = Layout.middle.frame(in: hd)
        #expect(hl.intersection(hr) == mid)
        let hm = Layout.hogMiddle.frame(in: hd)
        #expect(hm.minX == Layout.edge(1, in: hd))
        #expect(hm.maxX == Layout.edge(5, in: hd))
    }

    @Test(
        "Odd widths still tile exactly",
        arguments: [1437.0, 1001.0, 1725.0, 2559.0]
    )
    func oddWidths(_ width: CGFloat) {
        let odd = CGRect(x: 7, y: 3, width: width, height: 900)
        let a = Layout.farLeft.frame(in: odd)
        let b = Layout.middle.frame(in: odd)
        let c = Layout.farRight.frame(in: odd)
        #expect(a.maxX == b.minX)
        #expect(b.maxX == c.minX)
        #expect(a.width + b.width + c.width == width)
        let l = Layout.left.frame(in: odd)
        let r = Layout.right.frame(in: odd)
        #expect(l.width + r.width == width)
        #expect(Layout.full.frame(in: odd) == odd)
    }
}

@Suite("Hotkeys")
struct HotkeyTests {
    @Test("Bindings match the Divvy config")
    func bindings() {
        let l = Hotkey.leftArrow
        let r = Hotkey.rightArrow
        let u = Hotkey.upArrow
        #expect(Layout.left.hotkey
            == Hotkey(keyCode: l, modifiers: [.command]))
        #expect(Layout.right.hotkey
            == Hotkey(keyCode: r, modifiers: [.command]))
        #expect(Layout.full.hotkey
            == Hotkey(keyCode: u, modifiers: [.command]))
        #expect(Layout.farLeft.hotkey
            == Hotkey(keyCode: l, modifiers: [.command, .option]))
        #expect(Layout.farRight.hotkey
            == Hotkey(keyCode: r, modifiers: [.command, .option]))
        #expect(Layout.middle.hotkey
            == Hotkey(keyCode: u, modifiers: [.command, .option]))
        #expect(Layout.hogLeft.hotkey
            == Hotkey(keyCode: l, modifiers: [.command, .shift]))
        #expect(Layout.hogRight.hotkey
            == Hotkey(keyCode: r, modifiers: [.command, .shift]))
        #expect(Layout.hogMiddle.hotkey
            == Hotkey(keyCode: u, modifiers: [.command, .shift]))
    }

    @Test("Key codes are the Divvy plist values")
    func keyCodes() {
        #expect(Hotkey.leftArrow == 123)
        #expect(Hotkey.rightArrow == 124)
        #expect(Hotkey.upArrow == 126)
    }

    @Test("All nine hotkeys are distinct")
    func distinct() {
        let all = Set(Layout.allCases.map(\.hotkey))
        #expect(all.count == 9)
    }
}

@Suite("Hotkey symbols")
struct HotkeySymbolTests {
    @Test("Symbols read like the Divvy list")
    func symbols() {
        #expect(Layout.left.hotkey.symbols == "⌘←")
        #expect(Layout.full.hotkey.symbols == "⌘↑")
        #expect(Layout.farRight.hotkey.symbols == "⌥⌘→")
        #expect(Layout.hogMiddle.hotkey.symbols == "⇧⌘↑")
    }
}
