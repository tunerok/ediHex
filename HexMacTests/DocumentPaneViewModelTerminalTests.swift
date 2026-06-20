//
//  DocumentPaneViewModelTerminalTests.swift
//  HexMacTests
//

import AppKit
import Foundation
import Testing
@testable import HexMac

@Suite(.serialized)
@MainActor
struct DocumentPaneViewModelTerminalTests {
    private func makeTempFile(_ data: Data) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("HexMacVMTest-\(UUID().uuidString).bin")
        try data.write(to: url, options: .atomic)
        return url
    }

    private func makePaneWithFile(_ data: Data) throws -> (DocumentPaneViewModel, URL) {
        ensureTestApplication()
        let url = try makeTempFile(data)
        let pane = DocumentPaneViewModel()
        pane.loadFile(from: url)
        #expect(pane.isDocumentOpen, "loadFile failed: \(pane.errorMessage ?? "unknown error")")
        return (pane, url)
    }

    private func ensureTestApplication() {
        if NSApp == nil {
            let app = NSApplication.shared
            app.setActivationPolicy(.accessory)
        }
    }

    @Test func gotoUpdatesSelectionAndHistory() throws {
        let (pane, url) = try makePaneWithFile(Data((0..<32).map { UInt8($0) }))
        defer { try? FileManager.default.removeItem(at: url) }

        pane.executeTerminalCommand("goto 0x10")

        #expect(pane.selection?.start == 16)
        #expect(pane.scrollTargetOffset == 16)
        let expectedOffset = HexFormatter.offsetString(for: 16)
        #expect(pane.terminalHistory.contains { $0.text.contains("0x\(expectedOffset)") })
    }

    @Test func terminalIgnoredOnComparisonPane() throws {
        ensureTestApplication()
        let leftURL = try makeTempFile(Data([1, 2, 3]))
        let rightURL = try makeTempFile(Data([1, 2, 4]))
        defer {
            try? FileManager.default.removeItem(at: leftURL)
            try? FileManager.default.removeItem(at: rightURL)
        }

        let pane = DocumentPaneViewModel()
        pane.loadComparison(left: leftURL, right: rightURL)
        pane.executeTerminalCommand("goto 0")

        #expect(pane.terminalHistory.isEmpty)
    }

    @Test func terminalHistoryClearedOnLoadFile() throws {
        ensureTestApplication()
        let firstURL = try makeTempFile(Data([0, 1, 2]))
        let secondURL = try makeTempFile(Data([3, 4, 5]))
        defer {
            try? FileManager.default.removeItem(at: firstURL)
            try? FileManager.default.removeItem(at: secondURL)
        }

        let pane = DocumentPaneViewModel()
        pane.loadFile(from: firstURL)
        #expect(pane.isDocumentOpen)
        pane.executeTerminalCommand("goto 0")
        #expect(!pane.terminalHistory.isEmpty)

        pane.loadFile(from: secondURL)
        #expect(pane.isDocumentOpen)
        #expect(pane.terminalHistory.isEmpty)
    }

    @Test func terminalErrorAppendedToHistory() throws {
        let (pane, url) = try makePaneWithFile(Data([0, 1, 2]))
        defer { try? FileManager.default.removeItem(at: url) }

        pane.executeTerminalCommand("not-a-command")

        #expect(pane.terminalHistory.count == 2)
        #expect(pane.terminalHistory[0].kind == .input)
        #expect(pane.terminalHistory[1].kind == .error)
    }

    @Test func saveMarksDocumentClean() throws {
        let (pane, url) = try makePaneWithFile(Data([0, 1, 2, 3]))
        defer { try? FileManager.default.removeItem(at: url) }

        pane.beginSelection(at: 0)
        pane.endSelection(at: 0)
        pane.fillSelection(with: 0xFF)

        #expect(pane.isDirty)
        #expect(pane.selection != nil)

        pane.save()

        #expect(!pane.isDirty)
        #expect(pane.byte(at: 0) == 0xFF)
    }
}
