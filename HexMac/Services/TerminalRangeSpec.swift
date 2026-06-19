//
//  TerminalRangeSpec.swift
//  HexMac
//

import Foundation

struct TerminalRangeSpec: Equatable {
    let segments: [Range<Int>]

    var totalRawByteCount: Int {
        segments.reduce(0) { $0 + ($1.upperBound - $1.lowerBound) }
    }

    static func parse(positionalTokens: [String], fileSize: Int) -> TerminalRangeSpec? {
        guard !positionalTokens.isEmpty else { return nil }

        let joined = positionalTokens.joined(separator: " ")
        let segmentTexts = joined.split(separator: ",", omittingEmptySubsequences: true)
        guard !segmentTexts.isEmpty else { return nil }

        var segments: [Range<Int>] = []
        for segmentText in segmentTexts {
            let offsets = segmentText
                .split(whereSeparator: \.isWhitespace)
                .map { String($0) }
            guard offsets.count == 2,
                  let start = TerminalOffsetParser.parse(offsets[0]),
                  let end = TerminalOffsetParser.parse(offsets[1]) else {
                return nil
            }

            let lower = min(start, end)
            let upper = max(start, end) + 1
            guard lower >= 0, upper <= fileSize, lower < upper else { return nil }
            segments.append(lower..<upper)
        }

        return TerminalRangeSpec(segments: segments)
    }
}
