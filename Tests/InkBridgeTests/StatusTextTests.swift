import Testing
@testable import InkBridge

@Suite struct StatusTextTests {
    typealias State = InkFlowController.ConnectionState

    @Test func busyTellsTheUserToQuitTheOtherAppAndReplug() {
        let text = StatusItemController.statusText(for: .busy)
        #expect(text.title == "Supernote in use by another app")
        #expect(text.detail?.contains("Supernote Partner") == true)
        #expect(text.detail?.contains("unplug and replug") == true)
    }

    @Test func openFailedShowsTheErrorCodeAndTellsTheUserToReplug() {
        let text = StatusItemController.statusText(for: .openFailed(code: "0xe00002e2"))
        #expect(text.title.contains("0xe00002e2"))
        #expect(text.detail?.contains("replug") == true)
        #expect(text.detail?.contains("Supernote Partner") != true)
    }

    @Test func connectedShowsNameAndSerial() {
        let text = StatusItemController.statusText(for: .connected(name: "Supernote", serial: "SN1"))
        #expect(text.title == "Connected: Supernote")
        #expect(text.detail == "SN1")
    }

    @Test func disconnectedWaitsForTheDevice() {
        let text = StatusItemController.statusText(for: .disconnected)
        #expect(text.title == "Waiting for device…")
        #expect(text.detail == nil)
    }
}
