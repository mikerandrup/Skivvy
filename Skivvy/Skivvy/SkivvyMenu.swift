import ServiceManagement
import SkivvyCore
import SwiftUI

struct SkivvyMenu: View {
    let permission: AccessibilityPermission
    let loginItem: LoginItem

    var body: some View {
        Text("Skivvy replaces Divvy:")
        Divider()
        ForEach(Layout.allCases, id: \.self) { layout in
            Text("\(layout.hotkey.symbols)  \(layout.name)")
        }
        Divider()
        Text(statusLine)
        if !permission.isTrusted {
            Button("Open Accessibility Settings…") {
                permission.openSystemSettings()
            }
        }
        Toggle("Launch at Login", isOn: launchAtLogin)
        if loginItem.requiresApproval {
            Button("Approve in Login Items…") {
                SMAppService.openSystemSettingsLoginItems()
            }
        }
        Divider()
        Button("Quit Skivvy") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }

    var statusLine: String {
        permission.isTrusted
            ? "Accessibility: granted"
            : "Accessibility: needed"
    }

    var launchAtLogin: Binding<Bool> {
        Binding(
            get: { loginItem.isEnabled },
            set: { loginItem.setEnabled($0) }
        )
    }
}
