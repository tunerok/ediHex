//
//  TerminalOffsetParser.swift
//  HexMac
//

import Foundation

enum TerminalOffsetParser {
    static func parse(_ text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("0x") {
            let hex = String(trimmed.dropFirst(2))
            return Int(hex, radix: 16)
        }
        return Int(trimmed)
    }

    static func parseByte(_ text: String) -> UInt8? {
        guard let value = parse(text), value >= 0, value <= 0xFF else { return nil }
        return UInt8(value)
    }

    static func parseUInt64(_ text: String) -> UInt64? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("0x") {
            let hex = String(trimmed.dropFirst(2))
            return UInt64(hex, radix: 16)
        }
        return UInt64(trimmed)
    }
}
