import Foundation
import IOKit
import Testing
@testable import InkBridge

@Suite struct SupernoteHIDTests {
    @Test func matchesOnlyTheSupernoteUSBDevice() {
        #expect(SupernoteHID.VID == 0x2207)
        #expect(SupernoteHID.PID == 0x0007)
    }

    @Test func exclusiveAccessIsRecognizedAsAnotherAppHoldingTheDevice() {
        let error = SupernoteHID.OpenError(code: kIOReturnExclusiveAccess)
        #expect(error.isExclusiveAccess)
        #expect(error.hexCode == "0xe00002c5")
        #expect(error.localizedDescription.contains("Supernote Partner"))
    }

    @Test func otherOpenErrorsDoNotBlameAnotherApp() {
        let error = SupernoteHID.OpenError(code: kIOReturnNotPermitted)
        #expect(!error.isExclusiveAccess)
        #expect(error.hexCode == "0xe00002e2")
        #expect(!error.localizedDescription.contains("Supernote Partner"))
    }
}
