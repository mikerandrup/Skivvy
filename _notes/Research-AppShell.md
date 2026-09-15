# Menu bar agent shell on macOS 26/27 (research, Sept 2026)

Host: macOS 26.6.2, Xcode 27.0 (27A266a, final). Swift 6.4 toolchain.

## MenuBarExtra
- MenuBarExtra(_:systemImage:) with .menuBarExtraStyle(.menu). HIG says
  menu, not popover, for simple content.
- Menu content: Text renders as a disabled status line, Divider,
  Button("Quit") { NSApp.terminate(nil) } with .keyboardShortcut("q").
- Icon: SF Symbol, template rendering. Tahoe menu bar is transparent
  by default so template rendering keeps it legible.
- macOS 27 hides menu item symbol images by default. Use
  .labelStyle(.titleAndIcon) per item if one is ever wanted. Use
  Toggle inside Menu for checkmarks so the system draws them.
- macOS 27 renders the menu bar as one window. Standard MenuBarExtra
  apps are unaffected.
- Accessibility pane URL:
  x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility
  It is undocumented and may change. Primary path is the AX prompt
  itself (has an Open System Settings button); the URL is a fallback
  menu item.

## No Dock icon
- MenuBarExtra-only app still needs LSUIElement.
- With GENERATE_INFOPLIST_FILE = YES set the build setting
  INFOPLIST_KEY_LSUIElement = YES. Not an entitlement.

## Launch at login
- SMAppService.mainApp.register() / unregister(). No helper needed.
- SMAppService.openSystemSettingsLoginItems() is a supported deep link.
- Status: notRegistered, enabled, requiresApproval, notFound.
  register() throws kSMErrorAlreadyRegistered or
  kSMErrorLaunchDeniedByUser. After user disables in System Settings
  status is notFound. Never auto-re-register; derive toggle state
  from .status, re-read when the menu opens.
- Appears in System Settings > General > Login Items & Extensions.
- Debug builds from DerivedData register the DerivedData path. DTS
  warns that rebuilding many times a day with the same bundle id
  confuses BTM (stale entries, notFound, sfltool resetbtm + reboot).
  Recommendation: register only from a stable location like
  /Applications, or gate registration on not running under Xcode.

## Xcode 27 project defaults
- SWIFT_VERSION = 5.0 (Swift 5 language mode; Apple's own choice).
- SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor: every unannotated type
  and func is MainActor.
- SWIFT_APPROACHABLE_CONCURRENCY = YES.
- SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES: each file
  must explicitly import Carbon, ApplicationServices, CoreGraphics
  where it uses their symbols.
- C callbacks (Carbon EventHandlerUPP, CGEventTapCallBack) must be
  nonisolated top-level funcs or capture-free closures. Pass self via
  Unmanaged. Use MainActor.assumeIsolated inside only when delivery is
  guaranteed main thread (Carbon handlers are).
- MACOSX_DEPLOYMENT_TARGET = 26.6.2 is the host sw_vers, not an SDK
  version; Xcode wrote the host OS version. Set explicitly to 26.0.
- ARCHS resolves to arm64. Deployment target >= 27.0 drops x86_64 from
  ARCHS_STANDARD anyway.
- Remove the iOS/visionOS platform settings; macOS only.

## Sandbox, hardened runtime, signing
- ENABLE_APP_SANDBOX = NO (sandbox blocks AX entirely). Drop
  ENABLE_USER_SELECTED_FILES. No entitlements file needed.
- ENABLE_HARDENED_RUNTIME resolves NO in this project. Harmless
  either way for a local app. Not needed unless notarizing.
- Keep CODE_SIGN_STYLE = Automatic, Apple Development identity, team
  L3VZ8XTB77. Stable DR keeps the Accessibility grant across rebuilds.
- Fix PRODUCT_BUNDLE_IDENTIFIER before granting Accessibility (the DR
  includes it). Current value is a devplaceholder.
- tccutil reset Accessibility <bundle id> to clear a stale grant.

## App structure
- @main App with @NSApplicationDelegateAdaptor. Startup logic (AX
  trust check, hotkey registration, SMAppService status) in
  applicationDidFinishLaunching. Not in init.
- NSApplicationDelegateAdaptor is MainActor; delegate class is
  MainActor by default isolation.

## Sources
Apple docs for MenuBarExtra, MenuBarExtraStyle, HIG menu bar,
NSApplicationDelegateAdaptor, SMAppService and Status, LSUIElement,
build settings reference, hardened runtime, TN3127; macOS 26 and 27
release notes; Xcode 26.5 and 27 release notes; Apple forums 761314
761193 795626 760186 758393 777520 745720 751891 24288 775605 721745
730043 723669 760708 803515; SE-0466, SE-0444, SE-0461; massicotte,
donnywals, fatbobman, blakecrosley posts; sjhooper/TahoeMenuDemo;
nilcoalescing menu bar and launch-at-login posts.
