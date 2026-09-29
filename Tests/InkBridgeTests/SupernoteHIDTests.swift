import Testing
@testable import InkBridge

@Suite struct SupernoteHIDTests {
    @Test func matchesOnlyTheSupernoteUSBDevice() {
        #expect(SupernoteHID.VID == 0x2207)
        #expect(SupernoteHID.PID == 0x0007)
    }
}
