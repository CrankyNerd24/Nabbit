import Foundation
import WatchConnectivity

/// The watch's side of the connection: takes snapshots from the iPhone and sends it
/// what's tapped here. Requests go live when the iPhone is reachable and queue when it isn't.
final class PhoneLink: NSObject, WCSessionDelegate {
    static let shared = PhoneLink()

    /// Requests made before the session finished activating.
    private var waiting: [WatchRequest] = []

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func send(_ request: WatchRequest) {
        guard WCSession.default.activationState == .activated else {
            waiting.append(request)
            return
        }
        Self.deliver(request)
    }

    private func activated() {
        if let data = WCSession.default.receivedApplicationContext[WatchSnapshot.key] as? Data {
            WatchModel.shared.apply(data)
        }
        let queued = waiting
        waiting = []
        queued.forEach(Self.deliver)
        Self.deliver(.refresh)
    }

    /// Set up off the main actor, since the error handler runs on a background queue.
    nonisolated private static func deliver(_ request: WatchRequest) {
        let session = WCSession.default
        guard session.isReachable else {
            // A refresh only matters while the iPhone is around.
            if request != .refresh {
                session.transferUserInfo(request.dictionary)
            }
            return
        }
        session.sendMessage(request.dictionary, replyHandler: nil) { _ in
            if request != .refresh {
                WCSession.default.transferUserInfo(request.dictionary)
            }
        }
    }

    // MARK: - WCSessionDelegate

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
                             error: (any Error)?) {
        guard activationState == .activated else { return }
        Task { @MainActor in PhoneLink.shared.activated() }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        receive(applicationContext)
    }

    /// Complication updates from the iPhone carry the same snapshot.
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        receive(userInfo)
    }

    nonisolated private func receive(_ payload: [String: Any]) {
        guard let data = payload[WatchSnapshot.key] as? Data else { return }
        Task { @MainActor in WatchModel.shared.apply(data) }
    }
}
