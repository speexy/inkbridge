import Foundation
import Testing
@testable import InkBridge

@Suite struct ExcalidrawToolSyncTests {
    let t0 = Date(timeIntervalSinceReferenceDate: 1_000)

    @Test func flipInExcalidrawSendsTheEraserKey() {
        var sync = ExcalidrawToolSync()
        let decision = sync.update(eraser: true, now: t0, isExcalidrawFocused: { true })
        #expect(decision == .send(eraser: true))
    }

    @Test func noFlipSendsNothingAndSkipsTheFocusCheck() {
        var sync = ExcalidrawToolSync()
        var checks = 0
        let decision = sync.update(eraser: false, now: t0, isExcalidrawFocused: { checks += 1; return true })
        #expect(decision == .nothing)
        #expect(checks == 0)
    }

    @Test func flipInAnotherAppIsDeferredNotSent() {
        var sync = ExcalidrawToolSync()
        let decision = sync.update(eraser: true, now: t0, isExcalidrawFocused: { false })
        #expect(decision == .deferred)
        #expect(sync.lastSentEraser == false)
    }

    @Test func deferredFlipIsSentOnceExcalidrawIsFocusedAgain() {
        var sync = ExcalidrawToolSync()
        _ = sync.update(eraser: true, now: t0, isExcalidrawFocused: { false })
        let decision = sync.update(eraser: true, now: t0.addingTimeInterval(0.3), isExcalidrawFocused: { true })
        #expect(decision == .send(eraser: true))
    }

    @Test func focusIsNotRecheckedWithinTheRecheckInterval() {
        var sync = ExcalidrawToolSync()
        var checks = 0
        let notFocused = { checks += 1; return false }
        _ = sync.update(eraser: true, now: t0, isExcalidrawFocused: notFocused)
        _ = sync.update(eraser: true, now: t0.addingTimeInterval(0.1), isExcalidrawFocused: notFocused)
        _ = sync.update(eraser: true, now: t0.addingTimeInterval(0.2), isExcalidrawFocused: notFocused)
        #expect(checks == 1)
        _ = sync.update(eraser: true, now: t0.addingTimeInterval(0.25), isExcalidrawFocused: notFocused)
        #expect(checks == 2)
    }

    // Code-review scenario: eraser set in Excalidraw, pen flipped back in
    // another app, then Excalidraw regains focus. It must be switched back
    // to the pen, otherwise the pen tip erases.
    @Test func penFlipMadeElsewhereRestoresThePenInExcalidraw() {
        var sync = ExcalidrawToolSync()
        #expect(sync.update(eraser: true, now: t0, isExcalidrawFocused: { true }) == .send(eraser: true))
        #expect(sync.update(eraser: false, now: t0.addingTimeInterval(1), isExcalidrawFocused: { false }) == .deferred)
        let back = sync.update(eraser: false, now: t0.addingTimeInterval(2), isExcalidrawFocused: { true })
        #expect(back == .send(eraser: false))
    }

    @Test func flipAndFlipBackOutsideExcalidrawSendsNothing() {
        var sync = ExcalidrawToolSync()
        _ = sync.update(eraser: true, now: t0, isExcalidrawFocused: { false })
        let decision = sync.update(eraser: false, now: t0.addingTimeInterval(1), isExcalidrawFocused: { true })
        #expect(decision == .nothing)
    }

    @Test(arguments: [
        ("Excalidraw", true),
        ("My sketch — Excalidraw — Mozilla Firefox", true),
        ("drawing.excalidraw.md - Vault - Obsidian", true),
        ("Untitled - Google Docs", false),
        ("", false),
    ])
    func titleMatchingIsCaseInsensitive(title: String, expected: Bool) {
        #expect(ExcalidrawToolSync.isExcalidrawTitle(title) == expected)
    }
}
