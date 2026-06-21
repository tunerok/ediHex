//
//  DocumentPaneViewModelCompareNavigationTests.swift
//  ediHexTests
//

import AppKit
import Foundation
import Testing
@testable import ediHex

@Suite(.serialized)
@MainActor
struct DocumentPaneViewModelCompareNavigationTests {
    private func makeTempFile(_ data: Data) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ediHexCompare-\(UUID().uuidString).bin")
        try data.write(to: url, options: .atomic)
        return url
    }

    private func ensureTestApplication() {
        if NSApp == nil {
            let app = NSApplication.shared
            app.setActivationPolicy(.accessory)
        }
    }

    private func waitForDiffMapCompletion(_ pane: DocumentPaneViewModel, timeoutMs: Int = 10000) async throws {
        let deadline = ContinuousClock.now + .milliseconds(timeoutMs)
        while ContinuousClock.now < deadline {
            if !pane.isDiffMapLoading, pane.comparisonDiffChunkIndex != nil {
                return
            }
            try await Task.sleep(for: .milliseconds(25))
        }
        Issue.record("Compare diff map did not complete within timeout")
    }

    @Test func diffNavigationWrapsAround() async throws {
        ensureTestApplication()

        let chunkSize = ChunkedByteReader.defaultChunkSize
        let fileSize = chunkSize * 2
        var left = Array(repeating: UInt8(0x00), count: fileSize)
        var right = Array(repeating: UInt8(0x00), count: fileSize)
        right[1] = 0xFF
        right[chunkSize + 1] = 0xFF

        let leftURL = try makeTempFile(Data(left))
        let rightURL = try makeTempFile(Data(right))
        defer {
            try? FileManager.default.removeItem(at: leftURL)
            try? FileManager.default.removeItem(at: rightURL)
        }

        let pane = DocumentPaneViewModel()
        pane.loadComparison(left: leftURL, right: rightURL)

        try await waitForDiffMapCompletion(pane)

        #expect(pane.comparisonHasDifferences)
        #expect(pane.canNavigateNextDiff)
        #expect(pane.canNavigatePreviousDiff)
        #expect(pane.comparisonDiffCount == 2)
        #expect(pane.comparisonDiffChunkIndex?.diffChunkStarts == [0, chunkSize])

        #expect(pane.navigateToNextDiff())
        #expect(pane.comparisonCurrentDiffOffset == 1)
        #expect(pane.comparisonCurrentDiffRegionIndex == 0)

        #expect(pane.navigateToNextDiff())
        #expect(pane.comparisonCurrentDiffOffset == chunkSize + 1)
        #expect(pane.comparisonCurrentDiffRegionIndex == 1)

        #expect(pane.navigateToPreviousDiff())
        #expect(pane.comparisonCurrentDiffOffset == 1)

        #expect(pane.navigateToPreviousDiff())
        #expect(pane.comparisonCurrentDiffOffset == chunkSize + 1)
    }

    @Test func diffNavigationWithinSameChunk() async throws {
        ensureTestApplication()

        let left: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        let right: [UInt8] = [0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00]

        let leftURL = try makeTempFile(Data(left))
        let rightURL = try makeTempFile(Data(right))
        defer {
            try? FileManager.default.removeItem(at: leftURL)
            try? FileManager.default.removeItem(at: rightURL)
        }

        let pane = DocumentPaneViewModel()
        pane.loadComparison(left: leftURL, right: rightURL)

        try await waitForDiffMapCompletion(pane)

        #expect(pane.comparisonDiffCount == 2)

        #expect(pane.navigateToNextDiff())
        #expect(pane.comparisonCurrentDiffOffset == 1)

        #expect(pane.navigateToNextDiff())
        #expect(pane.comparisonCurrentDiffOffset == 5)

        #expect(pane.navigateToPreviousDiff())
        #expect(pane.comparisonCurrentDiffOffset == 1)

        #expect(pane.navigateToPreviousDiff())
        #expect(pane.comparisonCurrentDiffOffset == 5)
    }

    @Test func diffNavigationSkipsMultiByteRegion() async throws {
        ensureTestApplication()

        let left = Array(repeating: UInt8(0x00), count: 32)
        var right = Array(repeating: UInt8(0x00), count: 32)
        for index in 10...15 {
            right[index] = 0xFF
        }
        right[20] = 0xFF

        let leftURL = try makeTempFile(Data(left))
        let rightURL = try makeTempFile(Data(right))
        defer {
            try? FileManager.default.removeItem(at: leftURL)
            try? FileManager.default.removeItem(at: rightURL)
        }

        let pane = DocumentPaneViewModel()
        pane.loadComparison(left: leftURL, right: rightURL)

        try await waitForDiffMapCompletion(pane)

        #expect(pane.comparisonDiffCount == 2)

        pane.navigateToDiff(at: 10)
        #expect(pane.comparisonCurrentDiffOffset == 10)

        #expect(pane.navigateToNextDiff())
        #expect(pane.comparisonCurrentDiffOffset == 20)

        pane.navigateToDiff(at: 13)
        #expect(pane.navigateToNextDiff())
        #expect(pane.comparisonCurrentDiffOffset == 20)

        #expect(pane.navigateToPreviousDiff())
        #expect(pane.comparisonCurrentDiffOffset == 10)
    }

    @Test func diffNavigationUsesManualSelectionAnchor() async throws {
        ensureTestApplication()

        let left: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        let right: [UInt8] = [0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00]

        let leftURL = try makeTempFile(Data(left))
        let rightURL = try makeTempFile(Data(right))
        defer {
            try? FileManager.default.removeItem(at: leftURL)
            try? FileManager.default.removeItem(at: rightURL)
        }

        let pane = DocumentPaneViewModel()
        pane.loadComparison(left: leftURL, right: rightURL)

        try await waitForDiffMapCompletion(pane)

        pane.beginComparisonSelection(at: 1, side: .left)
        #expect(pane.comparisonCurrentDiffOffset == 1)

        #expect(pane.navigateToNextDiff())
        #expect(pane.comparisonCurrentDiffOffset == 5)

        pane.beginComparisonSelection(at: 5, side: .left)
        #expect(pane.navigateToPreviousDiff())
        #expect(pane.comparisonCurrentDiffOffset == 1)
    }

    @Test func diffNavigationMixedKindsWithSizeMismatch() async throws {
        ensureTestApplication()

        let left: [UInt8] = [0x00, 0x01, 0x02, 0x03]
        let right: [UInt8] = [0x00, 0xFF]

        let leftURL = try makeTempFile(Data(left))
        let rightURL = try makeTempFile(Data(right))
        defer {
            try? FileManager.default.removeItem(at: leftURL)
            try? FileManager.default.removeItem(at: rightURL)
        }

        let pane = DocumentPaneViewModel()
        pane.loadComparison(left: leftURL, right: rightURL)

        try await waitForDiffMapCompletion(pane)

        #expect(pane.comparisonDiffCount == 2)
        #expect(pane.comparisonDiffRegions[0].start == 1)
        #expect(pane.comparisonDiffRegions[0].leftKind == .changed)
        #expect(pane.comparisonDiffRegions[1].start == 2)
        #expect(pane.comparisonDiffRegions[1].leftKind == .deleted)

        #expect(pane.navigateToNextDiff())
        #expect(pane.comparisonCurrentDiffOffset == 1)
        #expect(pane.comparisonCurrentDiffRegionIndex == 0)

        #expect(pane.navigateToNextDiff())
        #expect(pane.comparisonCurrentDiffOffset == 2)
        #expect(pane.comparisonCurrentDiffRegionIndex == 1)

        #expect(pane.navigateToPreviousDiff())
        #expect(pane.comparisonCurrentDiffOffset == 1)

        #expect(pane.navigateToPreviousDiff())
        #expect(pane.comparisonCurrentDiffOffset == 2)
    }

    @Test func diffNavigationCrossChunkChangedThenDeleted() async throws {
        ensureTestApplication()

        let chunkSize = 8
        let left = Array(repeating: UInt8(0x00), count: chunkSize + 4)
        var right = Array(repeating: UInt8(0x00), count: chunkSize + 2)
        for index in 6..<(chunkSize + 2) {
            right[index] = 0xFF
        }

        let leftURL = try makeTempFile(Data(left))
        let rightURL = try makeTempFile(Data(right))
        defer {
            try? FileManager.default.removeItem(at: leftURL)
            try? FileManager.default.removeItem(at: rightURL)
        }

        let pane = DocumentPaneViewModel()
        pane.loadComparison(left: leftURL, right: rightURL)

        try await waitForDiffMapCompletion(pane)

        #expect(pane.comparisonDiffCount == 2)

        pane.navigateToDiff(at: 7)
        #expect(pane.navigateToNextDiff())
        #expect(pane.comparisonCurrentDiffOffset == chunkSize + 2)

        #expect(pane.navigateToPreviousDiff())
        #expect(pane.comparisonCurrentDiffOffset == 6)
    }
}
