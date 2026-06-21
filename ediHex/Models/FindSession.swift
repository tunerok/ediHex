//
//  FindSession.swift
//  ediHex
//

import Foundation

struct FindSession: Equatable {
    let pattern: [UInt8]
    let mode: FindPatternMode
    let entireFile: Bool
    let direction: FindDirection
    var matches: [Int]
    var currentIndex: Int
    var isScanningComplete: Bool = true

    var hasMatches: Bool {
        !matches.isEmpty
    }

    var currentMatch: Int? {
        guard currentIndex >= 0, currentIndex < matches.count else { return nil }
        return matches[currentIndex]
    }

    func statusText(isScanning: Bool, progress: Double) -> String? {
        guard hasMatches else { return nil }

        if isScanning {
            return String(
                localized: "Match \(currentIndex + 1) of \(matches.count) (scanning… \(String(format: "%.1f", progress * 100))%)",
                comment: "Find dialog status while scanning"
            )
        }

        return String(
            localized: "Match \(currentIndex + 1) of \(matches.count)",
            comment: "Find dialog status"
        )
    }
}

enum FindResult {
    case found(FindSession)
    case notFound
}
