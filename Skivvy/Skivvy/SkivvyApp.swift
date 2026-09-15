import SwiftUI

@main
struct SkivvyApp: App {
    @NSApplicationDelegateAdaptor private var delegate: AppDelegate

    var body: some Scene {
        MenuBarExtra("Skivvy", image: "MenuBarIcon") {
            SkivvyMenu(
                permission: delegate.permission,
                loginItem: delegate.loginItem
            )
        }
        .menuBarExtraStyle(.menu)
    }
}
