import AppKit
import SkivvyCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    let permission = AccessibilityPermission()
    let loginItem = LoginItem()
    private var windows: WindowController?
    private var hotkeys: HotkeyCenter?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let windows = WindowController(permission: permission)
        self.windows = windows
        let hotkeys = HotkeyCenter { layout in
            windows.apply(layout)
        }
        hotkeys.register()
        self.hotkeys = hotkeys
        permission.requestIfNeeded()
        loginItem.refresh()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeys?.unregister()
    }
}
