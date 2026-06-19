//
//  HashServiceTests.swift
//  HexMacTests
//

import XCTest
@testable import HexMac

final class HashServiceTests: XCTestCase {
    private let sample = Array("abc".utf8)

    func testMatchingAcceptsCommonAliases() {
        XCTAssertEqual(HashAlgorithm.matching("SHA-256"), .sha256)
        XCTAssertEqual(HashAlgorithm.matching("sha3-256"), .sha3_256)
        XCTAssertEqual(HashAlgorithm.matching("SHA3_384"), .sha3_384)
        XCTAssertEqual(HashAlgorithm.matching("sha512"), .sha512)
    }

    func testKnownVectors() {
        XCTAssertEqual(
            HashAlgorithm.calculate(.md5, data: sample),
            "900150983cd24fb0d6963f7d28e17f72"
        )
        XCTAssertEqual(
            HashAlgorithm.calculate(.sha256, data: sample),
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        )
        XCTAssertEqual(
            HashAlgorithm.calculate(.sha384, data: sample),
            "cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7"
        )
        XCTAssertEqual(
            HashAlgorithm.calculate(.sha3_256, data: sample),
            "3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532"
        )
    }

    func testTerminalHashCommand() {
        let bytes: [UInt8] = Array("abc".utf8)
        let result = TerminalCommandParser.execute(
            "hash sha384 0 2",
            fileSize: bytes.count,
            bytesProvider: { range in
                Array(bytes[range])
            }
        )

        guard case .output(let text) = result else {
            return XCTFail("Expected output")
        }

        XCTAssertEqual(
            text,
            "cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7"
        )
    }
}
