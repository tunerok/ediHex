//
//  HashService.swift
//  HexMac
//

import CommonCrypto
import CryptoKit
import Foundation

enum HashAlgorithm: String, CaseIterable, Identifiable {
    case md5
    case sha1
    case sha224
    case sha256
    case sha384
    case sha512
    case sha3_256
    case sha3_384
    case sha3_512

    var id: String { rawValue }

    var label: String {
        switch self {
        case .md5:
            "MD5"
        case .sha1:
            "SHA-1"
        case .sha224:
            "SHA-224"
        case .sha256:
            "SHA-256"
        case .sha384:
            "SHA-384"
        case .sha512:
            "SHA-512"
        case .sha3_256:
            "SHA3-256"
        case .sha3_384:
            "SHA3-384"
        case .sha3_512:
            "SHA3-512"
        }
    }

    static func matching(_ name: String) -> HashAlgorithm? {
        let normalized = normalizeName(name)
        return allCases.first {
            normalizeName($0.rawValue) == normalized || normalizeName($0.label) == normalized
        }
    }

    static func calculate(_ algorithm: HashAlgorithm, data: [UInt8]) -> String {
        switch algorithm {
        case .md5:
            hexString(Insecure.MD5.hash(data: data))
        case .sha1:
            hexString(Insecure.SHA1.hash(data: data))
        case .sha224:
            sha224(data: data)
        case .sha256:
            hexString(SHA256.hash(data: data))
        case .sha384:
            hexString(SHA384.hash(data: data))
        case .sha512:
            hexString(SHA512.hash(data: data))
        case .sha3_256:
            hexString(SHA3_256.hash(data: data))
        case .sha3_384:
            hexString(SHA3_384.hash(data: data))
        case .sha3_512:
            hexString(SHA3_512.hash(data: data))
        }
    }

    private static func normalizeName(_ name: String) -> String {
        name.lowercased()
            .unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) }
            .map(Character.init)
            .reduce(into: "") { $0.append($1) }
    }

    private static func hexString(_ bytes: some Sequence<UInt8>) -> String {
        bytes.map { String(format: "%02x", $0) }.joined()
    }

    private static func sha224(data: [UInt8]) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA224_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            _ = CC_SHA224(baseAddress, CC_LONG(buffer.count), &digest)
        }
        return hexString(digest)
    }
}
