//
//  TerminalSamplingFlags.swift
//  ediHex
//

import Foundation

struct TerminalSamplingFlags: Equatable {
    var every: Int?
    var mask: UInt8?
    var eq: UInt8?

    static func parse(from tokens: [String], startIndex: inout Int) -> Result<TerminalSamplingFlags, TerminalParseError> {
        parse(flagTokens: Array(tokens[startIndex...]))
    }

    static func parse(flagTokens: [String]) -> Result<TerminalSamplingFlags, TerminalParseError> {
        var flags = TerminalSamplingFlags()
        var index = 0

        while index < flagTokens.count {
            let token = flagTokens[index].lowercased()

            switch token {
            case "--every":
                guard index + 1 < flagTokens.count,
                      let value = TerminalOffsetParser.parse(flagTokens[index + 1]),
                      value >= 1 else {
                    return .failure(TerminalParseError(message: String(localized: "Usage: --every <N> (N >= 1)")))
                }
                flags.every = value
                index += 2

            case "--mask":
                guard index + 1 < flagTokens.count,
                      let value = TerminalOffsetParser.parseByte(flagTokens[index + 1]) else {
                    return .failure(TerminalParseError(message: String(localized: "Usage: --mask <byte>")))
                }
                flags.mask = value
                index += 2

            case "--eq":
                guard index + 1 < flagTokens.count,
                      let value = TerminalOffsetParser.parseByte(flagTokens[index + 1]) else {
                    return .failure(TerminalParseError(message: String(localized: "Usage: --eq <byte>")))
                }
                flags.eq = value
                index += 2

            default:
                if token.hasPrefix("--") {
                    return .success(flags)
                }
                return .failure(TerminalParseError(message: String(localized: "Unknown flag: \(flagTokens[index])")))
            }
        }

        return .success(flags)
    }

    func validate() -> TerminalParseError? {
        if eq != nil && mask == nil {
            return TerminalParseError(message: String(localized: "--eq requires --mask"))
        }
        return nil
    }
}
