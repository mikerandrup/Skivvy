# Window control on macOS 26/27 (research, Sept 2026)

## API status
- AX C API (AXUIElementCreateApplication, kAXFocusedWindowAttribute,
  kAXPositionAttribute, kAXSizeAttribute, AXUIElementSetAttributeValue,
  AXValueCreate) is not deprecated and remains the only public way to
  move another app's window. macOS 26 and 27 release notes add no
  replacement. Built-in tiling exposes nothing to third parties.
- AXError cases to handle: cannotComplete, illegalArgument,
  attributeUnsupported, invalidUIElement, notImplemented, apiDisabled,
  noValue.

## Coordinates
- AX: top-left origin, y down, anchored at top-left of the menu-bar
  screen. NSScreen: bottom-left origin, y up. Both in points; scale
  factor never enters.
- Flip (self-inverse) using ONLY NSScreen.screens[0]:
  y' = screens[0].frame.maxY - rect.maxY  (x unchanged)
- Never flip with NSScreen.main or the window's own screen.
- visibleFrame excludes menu bar, Dock, and notch. On Tahoe the top
  inset is 30pt on external displays and 37.5pt on notched built-in
  displays. Derive from frame vs visibleFrame; never hardcode. Re-read
  per operation.

## Order of operations
- Write size -> position -> size (Rectangle). macOS clamps size to the
  display the window is currently on, so the first size can be
  truncated and must be re-applied after the move. Read back and
  compare; success return does not mean it took.
- Check AXUIElementIsAttributeSettable(window, kAXSizeAttribute) first.
  Min/max constraints are enforced by the target app silently.
- AXEnhancedUserInterface (app-level attribute) causes animated moves
  that collide with consecutive writes (Chrome, Firefox). Read it, set
  false, write, restore. Skip toggling when VoiceOver or Switch
  Control is on. Electron uses AXManualAccessibility and is unaffected.
- Fullscreen: read AXFullScreen on the window; if true skip. AXSize on
  a fullscreen window returns illegalArgument.
- Sheets: kAXFocusedWindowAttribute can return a sheet; walk
  kAXParentAttribute when subrole is sheet or system dialog.
- Skip minimized windows.
- AXUIElementSetMessagingTimeout on the app element to bound hangs.

## Permission, sandbox, signing
- App Sandbox must be OFF (DTS: AX not supported in sandboxed apps).
- No entitlement exists for Accessibility.
- Hardened Runtime does not interfere.
- TCC keys the grant to the code signature's designated requirement.
  Ad-hoc signing changes the DR every build and the grant silently
  stops matching. Sign with a Development Team (personal team fine) so
  the DR is stable. Keep the bundle id fixed.
- Reset a stale grant: sudo tccutil reset Accessibility <bundle id>
- Prompt: AXIsProcessTrustedWithOptions with kAXTrustedCheckOptionPrompt
  = true. Prompt is async; poll AXIsProcessTrusted() afterward.
  Optional NSAccessibilityUsageDescription in Info.plist.
- macOS 26.1 had a bug adding binaries under Privacy & Security, fixed
  in 26.3.

## Screens
- Which screen: flip AX frame to NSScreen space, pick the screen whose
  frame contains it, else largest overlap, default NSScreen.main.
- Order screens by frame.minX for next display.
- Next display placement: compute fractions against source
  visibleFrame, apply to destination visibleFrame, clamp.

## Frontmost app and window
- NSWorkspace.shared.frontmostApplication -> AXUIElementCreateApplication(pid).
- kAXFocusedWindowAttribute; fall back to kAXMainWindowAttribute, then
  first of kAXWindowsAttribute; none means no window, stop.

## Sources
Apple docs (AX, NSScreen, TN3127, macOS 26/27 release notes), Apple
forums 810677 805556 794253 703188 721745, Rectangle source
(AccessibilityElement, ScreenDetection, CGExtension, StandardWindowMover,
BestEffortWindowMover, NextPrevDisplayCalculation), Hammerspoon PR 3836,
xa11y PR 7, Swindler issue 62, yashiki issue 185, yabai issue 1580.
