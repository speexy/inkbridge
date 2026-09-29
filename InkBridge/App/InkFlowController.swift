import AppKit
import IOKit.hid
import CoreGraphics

final class InkFlowController {

    enum ConnectionState: Equatable {
        case disconnected
        case connected(name: String, serial: String?)
        case busy
        case openFailed(code: String)

        static func afterFailedOpen(_ error: Error) -> ConnectionState {
            if let openError = error as? SupernoteHID.OpenError, !openError.isExclusiveAccess {
                return .openFailed(code: openError.hexCode)
            }
            return .busy
        }

        func afterSuccessfulOpen() -> ConnectionState {
            switch self {
            case .busy, .openFailed: return .disconnected
            default: return self
            }
        }
    }

    /// Limits reopens triggered by late-arriving devices, so a device that
    /// never shows up in the open set can't cause a reopen loop.
    struct ReopenLimiter {
        let cooldown: TimeInterval
        private var lastReopen: Date = .distantPast

        init(cooldown: TimeInterval) { self.cooldown = cooldown }

        mutating func allowReopen(at now: Date) -> Bool {
            guard now.timeIntervalSince(lastReopen) > cooldown else { return false }
            lastReopen = now
            return true
        }
    }

    private static let retryInterval: TimeInterval = 2.0

    private(set) var state: ConnectionState = .disconnected {
        didSet { onStateChange?(state) }
    }
    var onStateChange: ((ConnectionState) -> Void)?

    var excalidrawMode: Bool = false {
        didSet { mvm?.excalidrawMode = excalidrawMode }
    }

    var targetDisplayID: CGDirectDisplayID? {
        didSet { applyDisplay() }
    }

    private var mvm: MacOSVirtualMouse?
    private var hid: SupernoteHID?
    private var screenChangeObserver: NSObjectProtocol?
    private var retryTimer: Timer?
    private var arrivalReopenLimiter = ReopenLimiter(cooldown: 5.0)

    init() {
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.applyDisplay()
        }
    }

    deinit {
        if let observer = screenChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func start() {
        let frame = currentDisplayFrame()
        let mvm = MacOSVirtualMouse(displayFrame: frame)
        mvm.excalidrawMode = excalidrawMode
        let hid = SupernoteHID(mvm: mvm)

        hid.onMatched = { [weak self] device in
            let info = Self.deviceInfo(for: device)
            self?.state = .connected(name: info.name, serial: info.serial)
        }
        hid.onRemoved = { [weak self] _ in
            self?.state = .disconnected
        }
        hid.onArrivedAfterOpen = { [weak self] in
            guard let self, self.arrivalReopenLimiter.allowReopen(at: Date()) else { return false }
            // Deferred: we're inside the old manager's callback.
            DispatchQueue.main.async { self.restart() }
            return true
        }

        do {
            try hid.start()
            self.mvm = mvm
            self.hid = hid
            retryTimer?.invalidate()
            retryTimer = nil
            let next = state.afterSuccessfulOpen()
            if next != state { state = next }
        } catch {
            NSLog("InkBridge: hid.start() failed — \(error.localizedDescription)")
            state = .afterFailedOpen(error)
            scheduleRetry()
        }
    }

    private func restart() {
        stop()
        start()
    }

    private func scheduleRetry() {
        guard retryTimer == nil else { return }
        retryTimer = Timer.scheduledTimer(withTimeInterval: Self.retryInterval, repeats: true) { [weak self] _ in
            self?.start()
        }
    }

    func stop() {
        retryTimer?.invalidate()
        retryTimer = nil
        hid?.stop()
        hid = nil
        mvm = nil
        state = .disconnected
    }

    private func applyDisplay() {
        mvm?.displayFrame = currentDisplayFrame()
    }

    private func currentDisplayFrame() -> CGRect {
        // CGDisplayBounds returns the display's rect in global Quartz coordinates
        // (top-left origin, spanning all attached displays). This is the same
        // coordinate space CGEvent.location uses, so no AppKit-to-Quartz flip
        // is required. NSScreen.frame is AppKit coords (bottom-left) and would
        // need conversion — avoid it.
        if let id = targetDisplayID {
            let bounds = CGDisplayBounds(id)
            if bounds.size.width > 0 && bounds.size.height > 0 {
                return bounds
            }
        }
        return CGDisplayBounds(CGMainDisplayID())
    }

    private static func deviceInfo(for device: IOHIDDevice) -> (name: String, serial: String?) {
        // The USB product string is firmware-set and currently reports
        // "Supernote Nomad" on every Supernote model we've seen — including
        // the Manta. Until we have a way to fingerprint the model reliably,
        // surface the generic "Supernote" name and pair it with the serial.
        let serial = IOHIDDeviceGetProperty(device, kIOHIDSerialNumberKey as CFString) as? String
        return ("Supernote", serial)
    }
}
