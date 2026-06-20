//
//  CompareRowCacheTests.swift
//  HexMacTests
//

import Foundation
import Testing
@testable import HexMac

@Suite(.serialized)
struct CompareRowCacheTests {
    private func makeArray(_ bytes: [UInt8]) -> BTreeByteArray {
        let array = BTreeByteArray()
        array.insert(slice: MemoryByteSlice(data: Data(bytes)), at: 0)
        return array
    }

    @Test func batchRowBytesSplitsRows() {
        let bytes = Array((0..<64).map(UInt8.init))
        let leftArray = makeArray(bytes)
        let rightArray = makeArray(bytes)

        let batch = CompareRowLoader.buildContexts(
            for: 0..<4,
            bytesPerRow: 16,
            fileSize: 64,
            leftArray: leftArray,
            rightArray: rightArray,
            leftSize: 64,
            rightSize: 64
        )

        #expect(batch.count == 4)
        #expect(batch[0]?.leftBytes == Array((0..<16).map(UInt8.init)))
        #expect(batch[3]?.leftBytes == Array((48..<64).map(UInt8.init)))
    }

    @Test func rowZeroDiffSpansWhenBytesDiffer() {
        let leftBytes: [UInt8] = [0x01, 0x02, 0x03, 0x04]
        let rightBytes: [UInt8] = [0x01, 0xFF, 0x03, 0x04]
        let leftArray = makeArray(leftBytes)
        let rightArray = makeArray(rightBytes)

        let batch = CompareRowLoader.buildContexts(
            for: 0..<1,
            bytesPerRow: 16,
            fileSize: 4,
            leftArray: leftArray,
            rightArray: rightArray,
            leftSize: 4,
            rightSize: 4
        )

        let context = batch[0]
        #expect(context != nil)
        #expect(context?.leftDiffSpans?.count == 1)
        #expect(context?.rightDiffSpans?.count == 1)
        #expect(context?.leftDiffSpans?.first?.startColumn == 1)
        #expect(context?.leftDiffSpans?.first?.color == .yellow)
        #expect(context?.rightDiffSpans?.first?.startColumn == 1)
        #expect(context?.rightDiffSpans?.first?.color == .yellow)

        #expect(ByteCompareService.highlightColor(
            at: 1,
            side: .left,
            leftSize: 4,
            rightSize: 4,
            leftByte: 0x02,
            rightByte: 0xFF
        ) == .yellow)
    }

    @Test func cacheEvictsOldestRows() {
        var cache = CompareRowCache()
        let context = CompareRowContext(
            leftBytes: [0x01],
            rightBytes: [0x02],
            leftDiffSpans: nil,
            rightDiffSpans: nil
        )

        for row in 0..<(CompareRowCache.maxRows + 4) {
            cache.store(context, for: row)
        }

        #expect(cache.context(for: 0) == nil)
        #expect(cache.context(for: CompareRowCache.maxRows + 3) != nil)
    }
}
