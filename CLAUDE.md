# CLAUDE.md

Guidance for Claude Code sessions in this repository. The global
rules in `~/.claude/CLAUDE.md` apply first.

## What this is

Skivvy is a macOS 26+, Apple Silicon only menu bar utility with nine
hard-coded global shortcuts that move the frontmost window into column
layouts. It replaces Divvy for Mike's own machines. The spec is fixed
and lives in Linear MWD-1124. Do not add configuration, preferences,
grids, margins, or new shortcuts unless Mike asks.

Linear project: "Skivvy - Replacement for Divvy Utility" (team
MetroplexWeb). Research notes with sources are in `_notes/`. Read them
before touching hotkeys, Accessibility, or screen geometry; Apple
changes these areas often and the notes record what was verified in
September 2026.

## Commands

```
Shell/build.sh [Debug|Release]  # xcodebuild; prints the app path
Shell/run.sh                    # build Debug, quit any Skivvy, launch via open
Shell/test.sh                   # swift test in Skivvy/SkivvyCore
Shell/logs.sh --last 5m         # unified log for subsystem com.metroplexweb.Skivvy
Shell/reset-accessibility.sh    # tccutil reset Accessibility com.metroplexweb.Skivvy
Shell/install.sh                # Release build to /Applications, atomic swap, launch
```

Run scripts from the repo root. They resolve their own paths.

## Structure

- `Skivvy/Skivvy.xcodeproj` uses an Xcode 16+ synchronized folder
  group. Adding a Swift file to `Skivvy/Skivvy/` adds it to the target
  with no project edit. `Info.plist` is excluded from resources through
  a `PBXFileSystemSynchronizedBuildFileExceptionSet`; keep that.
- `Skivvy/Skivvy/` is the thin app layer: `SkivvyApp` (MenuBarExtra),
  `SkivvyMenu`, `AppDelegate`, `AccessibilityPermission`, `LoginItem`,
  `HotkeyCenter` (Carbon), `WindowController`.
- `Skivvy/SkivvyCore/` is a local Swift package holding all logic and
  all tests. Put every decision there so it is testable with
  `swift test`. The app target links it as a local package dependency.
- Tests are Swift Testing (`@Suite`, `@Test`, `#expect`). Do not add an
  Xcode test target; local package tests cannot run through
  `xcodebuild test` anyway.

## Build settings that matter

- `ENABLE_APP_SANDBOX = NO`. Accessibility does not work sandboxed.
- `INFOPLIST_KEY_LSUIElement = YES`. Menu bar agent, no Dock icon.
- `PRODUCT_BUNDLE_IDENTIFIER = com.metroplexweb.Skivvy`. Changing it
  orphans the Accessibility grant.
- Automatic signing with the Apple Development identity and team
  `L3VZ8XTB77`. Never switch to Sign to Run Locally; ad hoc signatures
  change every build and silently break the Accessibility grant.
- `MACOSX_DEPLOYMENT_TARGET = 26.0`, `SUPPORTED_PLATFORMS = macosx`.
- Swift 5 language mode with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
  and `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`. Every
  file must import the framework whose members it uses (`Carbon`,
  `ApplicationServices`, `AppKit`). C callbacks such as the Carbon
  event handler must be `nonisolated` top-level functions that reach
  the owner through `Unmanaged` and use `MainActor.assumeIsolated`.

## Design decisions to preserve

- Hotkeys use Carbon `RegisterEventHotKey`, not a CGEvent tap and not
  `NSEvent.addGlobalMonitorForEvents`. Carbon needs no permission and
  swallows the keystroke. A tap is the documented fallback only if a
  specific app proves to receive the key first.
- Coordinate flip between NSScreen and Accessibility space uses only
  the primary screen height (`NSScreen.screens[0]`). Never flip with
  the window's own screen.
- Window writes go size, position, size, then read back. Keep the
  `AXEnhancedUserInterface` suppression.
- Launch at Login is a user toggle, never automatic. Registering from
  a DerivedData build corrupts the login items database.
- Repeat-press cycling uses the last `Placement` record first (same
  window, same layout, window still within `Resolver.tolerance` of the
  achieved or requested frame), then the ideal-frame comparison. The
  record is what lets a clamped window keep cycling.

## Gotchas

- `log` is a zsh builtin. Use `/usr/bin/log` or `Shell/logs.sh`.
- Launch the app with `open -a`, not by executing the binary, so Skivvy
  is its own TCC responsible process.
- After `Shell/run.sh` a Debug copy exists in DerivedData and Launch
  Services indexes it. Delete it and unregister with `lsregister -u`
  when finished so Spotlight does not offer it. `/Applications/Skivvy.app`
  is the one that should run daily.
- The Accessibility integration suite self-skips unless the terminal
  running `swift test` has the Accessibility grant. Skipped is expected
  in a Claude Code session.
- Synthesized keystrokes from a terminal are blocked on macOS 26, so
  end-to-end hotkey presses need a human.

## Style

Narrow lines, self-documenting names, comments only where the reason
is not obvious from the code. Public API in the core package is
documented with a short doc comment where behavior is subtle.
