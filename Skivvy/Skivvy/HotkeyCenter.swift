import AppKit
import Carbon
import SkivvyCore
import os

/// Registers the nine global shortcuts with Carbon. Carbon
/// hotkeys are matched inside WindowServer, need no permission,
/// and the frontmost app never sees the keystroke.
final class HotkeyCenter {
    private let onPress: (Layout) -> Void
    private var hotkeyRefs: [EventHotKeyRef] = []
    private var handlerRef: EventHandlerRef?
    private var sessionObserver: NSObjectProtocol?

    private let logger = Logger(
        subsystem: "com.metroplexweb.Skivvy", category: "hotkeys"
    )

    nonisolated static let signature: OSType = 0x534B_5659  // "SKVY"

    init(onPress: @escaping (Layout) -> Void) {
        self.onPress = onPress
    }

    func register() {
        unregister()
        installHandler()
        for (index, layout) in Layout.allCases.enumerated() {
            registerHotkey(layout, id: UInt32(index))
        }
        observeSessionChanges()
    }

    func unregister() {
        for ref in hotkeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotkeyRefs.removeAll()
        if let handlerRef {
            RemoveEventHandler(handlerRef)
            self.handlerRef = nil
        }
    }

    fileprivate func handle(id: UInt32) {
        let layouts = Layout.allCases
        guard Int(id) < layouts.count else { return }
        onPress(layouts[Int(id)])
    }

    private func installHandler() {
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let context = Unmanaged.passUnretained(self).toOpaque()
        let status = InstallEventHandler(
            GetEventDispatcherTarget(),
            hotkeyEventHandler,
            1,
            &spec,
            context,
            &handlerRef
        )
        if status != noErr {
            logger.error("InstallEventHandler failed: \(status)")
        }
    }

    private func registerHotkey(_ layout: Layout, id: UInt32) {
        let key = layout.hotkey
        let hotkeyID = EventHotKeyID(
            signature: Self.signature, id: id
        )
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            key.keyCode,
            Self.carbonModifiers(key.modifiers),
            hotkeyID,
            GetEventDispatcherTarget(),
            0,
            &ref
        )
        if status == noErr, let ref {
            hotkeyRefs.append(ref)
            logger.info("Registered \(layout.name, privacy: .public)")
        } else {
            logger.error(
                "RegisterEventHotKey \(layout.name, privacy: .public) failed: \(status)"
            )
        }
    }

    private func observeSessionChanges() {
        guard sessionObserver == nil else { return }
        sessionObserver = NSWorkspace.shared.notificationCenter
            .addObserver(
                forName: NSWorkspace.sessionDidBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.register()
                }
            }
    }

    static func carbonModifiers(
        _ modifiers: Set<Hotkey.Modifier>
    ) -> UInt32 {
        var flags = 0
        if modifiers.contains(.command) { flags |= cmdKey }
        if modifiers.contains(.option) { flags |= optionKey }
        if modifiers.contains(.shift) { flags |= shiftKey }
        return UInt32(flags)
    }
}

private nonisolated func hotkeyEventHandler(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event, let userData else { return OSStatus(eventNotHandledErr) }
    var hotkeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotkeyID
    )
    guard status == noErr,
          hotkeyID.signature == HotkeyCenter.signature
    else { return OSStatus(eventNotHandledErr) }
    let center = Unmanaged<HotkeyCenter>
        .fromOpaque(userData)
        .takeUnretainedValue()
    MainActor.assumeIsolated {
        center.handle(id: hotkeyID.id)
    }
    return noErr
}
