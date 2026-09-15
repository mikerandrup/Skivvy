import AppKit
import ApplicationServices
import Observation
import os

@Observable
final class AccessibilityPermission {
    private(set) var isTrusted = AXIsProcessTrusted() {
        didSet {
            if isTrusted != oldValue {
                logger.info("Accessibility trusted: \(self.isTrusted)")
            }
        }
    }
    private var polling = false

    private let logger = Logger(
        subsystem: "com.metroplexweb.Skivvy", category: "permission"
    )

    static let settingsURL = URL(
        string: "x-apple.systempreferences:"
            + "com.apple.preference.security?Privacy_Accessibility"
    )!

    func refresh() {
        isTrusted = AXIsProcessTrusted()
    }

    /// Shows the system prompt once and polls until granted.
    /// The prompt is asynchronous and the return value only
    /// reflects the current state.
    func requestIfNeeded() {
        refresh()
        logger.info("Accessibility trusted at launch: \(self.isTrusted)")
        guard !isTrusted else { return }
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
        let options = [key as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        pollUntilTrusted()
    }

    func openSystemSettings() {
        NSWorkspace.shared.open(Self.settingsURL)
    }

    private func pollUntilTrusted() {
        guard !polling else { return }
        polling = true
        Task {
            while !isTrusted {
                try? await Task.sleep(for: .seconds(1))
                refresh()
            }
            polling = false
        }
    }
}
