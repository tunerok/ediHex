//
//  TextEncodingMode.swift
//  ediHex
//

import Foundation

enum TextEncodingMode: String, CaseIterable, Identifiable {
    case ascii
    case utf8
    case utf16LittleEndian
    case utf16BigEndian
    case isoLatin1
    case windowsCP1252
    case macRoman

    var id: String { rawValue }

    var label: String {
        switch self {
        case .ascii:
            String(localized: "ASCII")
        case .utf8:
            String(localized: "UTF-8")
        case .utf16LittleEndian:
            String(localized: "UTF-16 LE")
        case .utf16BigEndian:
            String(localized: "UTF-16 BE")
        case .isoLatin1:
            String(localized: "Latin-1")
        case .windowsCP1252:
            String(localized: "Windows-1252")
        case .macRoman:
            String(localized: "Mac Roman")
        }
    }

    var stringEncoding: String.Encoding {
        switch self {
        case .ascii:
            .ascii
        case .utf8:
            .utf8
        case .utf16LittleEndian:
            .utf16LittleEndian
        case .utf16BigEndian:
            .utf16BigEndian
        case .isoLatin1:
            .isoLatin1
        case .windowsCP1252:
            .windowsCP1252
        case .macRoman:
            .macOSRoman
        }
    }
}
