//
//  TerminalCRCOptions.swift
//  ediHex
//

import Foundation

struct TerminalCRCOptions: Equatable {
    var preset: CRCPreset?
    var configuration: CRCConfiguration
    var reverseByteOrder: Bool

    static let `default` = TerminalCRCOptions(
        preset: .crc32IsoHdlc,
        configuration: CRCPreset.crc32IsoHdlc.configuration,
        reverseByteOrder: false
    )

    var displayLabel: String {
        preset?.label ?? configuration.algorithm.label
    }

    static func parse(from tokens: [String], startIndex: inout Int) -> Result<TerminalCRCOptions, TerminalParseError> {
        parse(flagTokens: Array(tokens[startIndex...]))
    }

    static func parse(flagTokens: [String]) -> Result<TerminalCRCOptions, TerminalParseError> {
        var options = TerminalCRCOptions(
            preset: nil,
            configuration: CRCPreset.crc32IsoHdlc.configuration,
            reverseByteOrder: false
        )
        var index = 0

        while index < flagTokens.count {
            let token = flagTokens[index].lowercased()

            switch token {
            case "--preset":
                guard index + 1 < flagTokens.count,
                      let preset = CRCPreset.matching(flagTokens[index + 1]) else {
                    return .failure(TerminalParseError(message: String(localized: "Usage: --preset <name>")))
                }
                options.preset = preset
                options.configuration = preset.configuration
                index += 2

            case "--crc8":
                options.preset = nil
                options.configuration.algorithm = .crc8
                index += 1

            case "--crc16":
                options.preset = nil
                options.configuration.algorithm = .crc16
                index += 1

            case "--crc32":
                options.preset = nil
                options.configuration.algorithm = .crc32
                index += 1

            case "--poly":
                guard index + 1 < flagTokens.count else {
                    return .failure(TerminalParseError(message: String(localized: "Usage: --poly <hex>")))
                }
                options.preset = nil
                options.configuration.setPolynomial(fromHex: flagTokens[index + 1])
                index += 2

            case "--init":
                guard index + 1 < flagTokens.count else {
                    return .failure(TerminalParseError(message: String(localized: "Usage: --init <hex>")))
                }
                options.preset = nil
                options.configuration.setInitialValue(fromHex: flagTokens[index + 1])
                index += 2

            case "--xorout":
                guard index + 1 < flagTokens.count else {
                    return .failure(TerminalParseError(message: String(localized: "Usage: --xorout <hex>")))
                }
                options.preset = nil
                options.configuration.setXorOut(fromHex: flagTokens[index + 1])
                index += 2

            case "--refin":
                options.preset = nil
                options.configuration.refin = true
                index += 1

            case "--refout":
                options.preset = nil
                options.configuration.refout = true
                index += 1

            case "--reverse":
                options.reverseByteOrder = true
                index += 1

            default:
                return .success(options)
            }
        }

        return .success(options)
    }
}

extension CRCPreset {
    static func matching(_ name: String) -> CRCPreset? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowered = trimmed.lowercased()

        if let exact = allCases.first(where: { $0.rawValue.lowercased() == lowered }) {
            return exact
        }

        let normalizedQuery = normalizePresetName(lowered)
        if let match = allCases.first(where: { normalizePresetName($0.rawValue) == normalizedQuery }) {
            return match
        }

        if let suffixMatch = allCases.first(where: {
            normalizePresetName($0.rawValue).hasSuffix(normalizedQuery)
                || normalizePresetName($0.label).hasSuffix(normalizedQuery)
        }) {
            return suffixMatch
        }

        return allCases.first {
            normalizePresetName($0.label) == normalizedQuery
        }
    }

    private static func normalizePresetName(_ value: String) -> String {
        value
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
    }
}
