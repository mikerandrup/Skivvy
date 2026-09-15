import Observation
import ServiceManagement
import os

@Observable
final class LoginItem {
    private(set) var status = SMAppService.mainApp.status

    private let logger = Logger(
        subsystem: "com.metroplexweb.Skivvy", category: "login"
    )

    var isEnabled: Bool { status == .enabled }
    var requiresApproval: Bool { status == .requiresApproval }

    func refresh() {
        status = SMAppService.mainApp.status
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            logger.error("Login item change failed: \(error)")
        }
        refresh()
    }
}
