import Foundation
import IOKit
import Testing
@testable import InkBridge

@Suite struct ConnectionStateTests {
    typealias State = InkFlowController.ConnectionState

    @Test func exclusiveAccessFailureShowsBusy() {
        let error = SupernoteHID.OpenError(code: kIOReturnExclusiveAccess)
        #expect(State.afterFailedOpen(error) == .busy)
    }

    @Test func otherOpenFailureShowsItsErrorCode() {
        let error = SupernoteHID.OpenError(code: kIOReturnNotPermitted)
        #expect(State.afterFailedOpen(error) == .openFailed(code: "0xe00002e2"))
    }

    @Test func unknownErrorTypeFallsBackToBusy() {
        struct Unrelated: Error {}
        #expect(State.afterFailedOpen(Unrelated()) == .busy)
    }

    @Test(arguments: [State.busy, .openFailed(code: "0xe00002e2")])
    func successfulOpenClearsAFailureState(_ state: State) {
        #expect(state.afterSuccessfulOpen() == .disconnected)
    }

    @Test(arguments: [State.disconnected, .connected(name: "Supernote", serial: "SN1")])
    func successfulOpenKeepsOtherStates(_ state: State) {
        #expect(state.afterSuccessfulOpen() == state)
    }
}

@Suite struct ReopenLimiterTests {
    let start = Date(timeIntervalSinceReferenceDate: 1_000)

    @Test func firstReopenIsAllowed() {
        var limiter = InkFlowController.ReopenLimiter(cooldown: 5)
        let allowed = limiter.allowReopen(at: start)
        #expect(allowed)
    }

    @Test func reopenWithinCooldownIsRefused() {
        var limiter = InkFlowController.ReopenLimiter(cooldown: 5)
        _ = limiter.allowReopen(at: start)
        let allowedAfter1s = limiter.allowReopen(at: start.addingTimeInterval(1))
        #expect(!allowedAfter1s)
        let allowedAt5s = limiter.allowReopen(at: start.addingTimeInterval(5))
        #expect(!allowedAt5s)
    }

    @Test func reopenAfterCooldownIsAllowedAgain() {
        var limiter = InkFlowController.ReopenLimiter(cooldown: 5)
        _ = limiter.allowReopen(at: start)
        let allowed = limiter.allowReopen(at: start.addingTimeInterval(5.1))
        #expect(allowed)
    }

    @Test func refusedAttemptsDoNotExtendTheCooldown() {
        var limiter = InkFlowController.ReopenLimiter(cooldown: 5)
        _ = limiter.allowReopen(at: start)
        _ = limiter.allowReopen(at: start.addingTimeInterval(4))
        let allowed = limiter.allowReopen(at: start.addingTimeInterval(5.1))
        #expect(allowed)
    }
}
