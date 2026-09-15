# Global hotkeys on macOS 26/27 (research, Sept 2026)

## Decision: Carbon RegisterEventHotKey
- Still present and working on macOS 26 and 27, Apple Silicon. No
  deprecation macro on the API, nothing in macOS 27 or Xcode 27
  release notes. KeyboardShortcuts 3.1.0 (Sept 2026) uses it and
  reports macOS 27 compatibility.
- Zero TCC permission. No dialog of any kind.
- Swallows the keystroke: matched in WindowServer, the frontmost app
  never sees the keyDown. So ⌘← will not also move the text cursor.
- All nine combos include ⌘, so the macOS 15 restriction on ⌥-only
  hotkeys does not apply.
- No system-wide hotkey uses ⌘/⌥⌘/⇧⌘ + arrow. Built-in window tiling
  on 26 and 27 is all Fn-Control based. ⌘←, ⌘↑, ⇧⌘← and friends are
  app-level responder bindings, so a Carbon hotkey wins.
- One contested claim (QUICOPY on Zed) says self-drawn apps can see
  the key first. Verify against a terminal app during testing.

## Implementation details
- Key codes: kVK_LeftArrow 0x7B (123), kVK_RightArrow 0x7C (124),
  kVK_UpArrow 0x7E (126). Same numbers Divvy stored.
- Modifiers: cmdKey, cmdKey|optionKey, cmdKey|shiftKey.
- Nine RegisterEventHotKey calls on the main thread with distinct
  EventHotKeyID.id values, target GetEventDispatcherTarget().
- inOptions: 0 or kEventHotKeyExclusive. Exclusive blocks other
  non-exclusive registrants; returns eventHotKeyExistsErr (-9878) if
  another exclusive registrant exists.
- One InstallEventHandler for {kEventClassKeyboard, kEventHotKeyPressed}.
  Read the id via GetEventParameter(kEventParamDirectObject,
  typeEventHotKeyID). Return noErr.
- Handler is a @convention(c) function so it must be nonisolated and
  capture nothing. Pass self via Unmanaged userData. Carbon delivers
  on the main thread, so MainActor.assumeIsolated inside is safe
  (KeyboardShortcuts does exactly this).
- Not thread safe; register and unregister on main.
- Registering a combo owned by macOS returns noErr and silently never
  fires. Not a concern for our combos.
- Unregister on quit. Re-register on
  NSWorkspace.sessionDidBecomeActiveNotification (iTerm2 practice).
- Agent app must use LSUIElement, not LSBackgroundOnly.

## Fallback: CGEvent.tapCreate
- Only if some app proves to swallow keys ahead of Carbon.
- Session tap, headInsert, options .defaultTap, return nil to swallow.
- Needs Accessibility (which we have anyway).
- Must handle tapDisabledByTimeout and tapDisabledByUserInput by
  re-enabling, and poll tapIsEnabled after sleep/wake (Tahoe 26.3.1
  bug). Tear down cleanly on quit (Tahoe WindowServer loop on
  orphaned taps).
- NSEvent.addGlobalMonitorForEvents cannot swallow. Not usable.

## Sources
Apple forums 763878 735223 707680 122492 758554, Apple docs for
NSEvent global monitor and CGEvent.tapCreate, CarbonEvents.h header,
macOS 27 and Xcode 27 release notes, KeyboardShortcuts repo and
releases, go-macos/hotkey, nick-liu Tahoe hotkey post, ghostty
discussion 11819, PlayCover issue 2105, alt-tab KeyboardEvents.swift,
Apple support window tiling pages for 26 and 27.
