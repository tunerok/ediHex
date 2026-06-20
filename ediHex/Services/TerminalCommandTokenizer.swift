//
//  TerminalCommandTokenizer.swift
//  ediHex
//

import Foundation

enum TerminalCommandTokenizer {
    private static let samplingValueFlags: Set<String> = ["--every", "--mask", "--eq"]
    private static let crcValueFlags: Set<String> = ["--preset", "--poly", "--init", "--xorout"]
    private static let crcBooleanFlags: Set<String> = ["--refin", "--refout", "--reverse", "--crc8", "--crc16", "--crc32"]
    private static let readBooleanFlags: Set<String> = ["--le", "--be"]

    static func split(commandTokens: [String]) -> (flagTokens: [String], positionalTokens: [String]) {
        guard commandTokens.count > 1 else {
            return ([], [])
        }

        var flagTokens: [String] = []
        var positionalTokens: [String] = []
        var index = 1

        while index < commandTokens.count {
            let token = commandTokens[index]
            let lowered = token.lowercased()

            if lowered.hasPrefix("--") {
                flagTokens.append(token)
                if consumesValue(lowered), index + 1 < commandTokens.count,
                   !commandTokens[index + 1].hasPrefix("--") {
                    flagTokens.append(commandTokens[index + 1])
                    index += 2
                } else {
                    index += 1
                }
            } else {
                positionalTokens.append(token)
                index += 1
            }
        }

        return (flagTokens, positionalTokens)
    }

    static func validate(
        flagTokens: [String],
        allowCRCFlags: Bool,
        allowSamplingFlags: Bool,
        allowReadFlags: Bool = false
    ) -> TerminalParseError? {
        var index = 0

        while index < flagTokens.count {
            let flag = flagTokens[index].lowercased()
            guard flag.hasPrefix("--") else {
                index += 1
                continue
            }

            if samplingValueFlags.contains(flag) {
                guard allowSamplingFlags else {
                    return TerminalParseError(message: String(localized: "Unknown flag: \(flagTokens[index])"))
                }
                index += 2
                continue
            }

            if crcValueFlags.contains(flag) || crcBooleanFlags.contains(flag) {
                guard allowCRCFlags else {
                    return TerminalParseError(message: String(localized: "Unknown flag: \(flagTokens[index])"))
                }
                index += consumesValue(flag) ? 2 : 1
                continue
            }

            if readBooleanFlags.contains(flag) {
                guard allowReadFlags else {
                    return TerminalParseError(message: String(localized: "Unknown flag: \(flagTokens[index])"))
                }
                index += 1
                continue
            }

            return TerminalParseError(message: String(localized: "Unknown flag: \(flagTokens[index])"))
        }

        return nil
    }

    private static func consumesValue(_ flag: String) -> Bool {
        samplingValueFlags.contains(flag) || crcValueFlags.contains(flag)
    }
}
