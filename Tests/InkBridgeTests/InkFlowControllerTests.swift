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
