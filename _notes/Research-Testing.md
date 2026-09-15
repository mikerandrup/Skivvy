# Building and testing from the CLI (research, Sept 2026)

Host: Xcode 27.0 (27A266a), macOS 26.6.2. xcbeautify, xcodegen, tuist
are NOT installed. Do not install anything.

## Structure decision
- All decision logic lives in a local Swift package SkivvyCore
  (geometry, layout, screen cycling, an AX windowing protocol with a
  real adapter and a fake). Swift Testing tests run with swift test.
  No xcodeproj test target, no scheme surgery. Rectangle, Loop and
  AeroSpace all test this way (mocked elements, pure geometry).
- App target depends on the package via XCLocalSwiftPackageReference +
  XCSwiftPackageProductDependency + packageProductDependencies on the
  target + a PBXBuildFile with productRef in the Frameworks phase.
- Local package test targets cannot be run through xcodebuild test
  (known limitation). Use swift test.

## Swift Testing syntax
- import Testing; @Suite, @Test, #expect, #require.
- Parameterized: @Test(arguments: [...]) and zip(...) for pairs.
- Traits: .serialized, .enabled(if:), .timeLimit(.minutes(n)).
- Suites need a zero-arg init. Tests run in parallel by default.
- @testable import needs ENABLE_TESTABILITY (Debug default).

## Commands
P=/Users/mike/RahlusDevGit/Skivvy-macOSWindowSizer/Skivvy
xcodebuild -project "$P/Skivvy.xcodeproj" -scheme Skivvy \
  -configuration Debug -destination 'platform=macOS,arch=arm64' build
APP=$(xcodebuild -project "$P/Skivvy.xcodeproj" -scheme Skivvy \
  -configuration Debug -showBuildSettings 2>/dev/null \
  | awk '/ CODESIGNING_FOLDER_PATH =/{print $3}')
open -a "$APP"        # app is its own TCC responsible process
pkill -x Skivvy
cd "$P/SkivvyCore" && swift test
swift test --filter 'SuiteName'

## TCC and tests
- TCC attributes access to the responsible process. swift test from
  a terminal means the terminal app is responsible. Grant
  Accessibility to the terminal once and AX calls inside tests work.
- open -a launches Skivvy as its own responsible process, so Skivvy
  gets its own prompt and grant.
- Direct exec of the binary keeps Terminal responsible. Use open.
- Ad-hoc signing breaks the grant every rebuild. Apple Development
  signing with a team is stable. Keep it.
- Changing the bundle id orphans the grant. Fix the bundle id first.
- tccutil reset Accessibility <bundle id> to clear.

## Verifying a window frame without Accessibility
- CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID)
  returns kCGWindowBounds (top-left global coords, same as AX) with
  no permission prompt. kCGWindowName is absent without Screen
  Recording; match by kCGWindowOwnerPID and kCGWindowNumber, not
  title.

## Integration test approach
- Suite gated with .enabled(if: AXIsProcessTrusted()) and
  .serialized. Launch TextEdit via NSWorkspace.openApplication, get
  its window via AX, apply a layout, read back via AX and via
  CGWindowList bounds, terminate TextEdit afterward.

## Xcode 27 testing notes
- XCTest and Swift Testing interop on by default.
- -only-testing accepts Swift Testing ids Target/Suite/func().
- xcrun xcresulttool get test-results summary --path X.xcresult
