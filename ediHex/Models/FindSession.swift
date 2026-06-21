//
//  FindSession.swift
//  ediHex
//

import Foundation

struct FindSession: Equatable {
    let queryText: String
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

    var parametersDescription: String {
        let scope = entireFile
            ? String(localized: "Entire file", comment: "Find scope label")
            : String(localized: "From cursor", comment: "Find scope label")
        let modeLabel = mode == .hex
            ? String(localized: "Hex", comment: "Find mode label")
            : String(localized: "ASCII", comment: "Find mode label")

        if entireFile {
            return "\(scope) · \(modeLabel)"
        }

        let directionLabel = direction == .down
            ? String(localized: "Down", comment: "Find direction label")
            : String(localized: "Up", comment: "Find direction label")
        return "\(scope) · \(directionLabel) · \(modeLabel)"
    }

    var resultsSummary: String {
        if hasMatches {
            if isScanningComplete {
                return String(localized: "\(matches.count) matches", comment: "Find result count")
            }
            return String(
                localized: "\(matches.count) matches (scan stopped)",
                comment: "Find result count after interrupted scan"
            )
        }

        return String(localized: "Not found", comment: "Find result when no matches")
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
