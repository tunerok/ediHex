//
//  HexSelectionSpansTests.swift
//  ediHexTests
//

import XCTest
@testable import ediHex

final class HexSelectionSpansTests: XCTestCase {
    func testSpansForSelectionInsideRow() {
        let selection = HexSelection(anchor: 18, active: 20)

        let spans = HexSelectionSpans.spans(
            for: 1,
            bytesPerRow: 16,
            fileSize: 32,
            selection: selection
        )

        XCTAssertEqual(spans?.count, 1)
        XCTAssertEqual(spans?[0].startColumn, 2)
        XCTAssertEqual(spans?[0].endColumn, 4)
    }

    func testSpansForSelectionSpanningEntireRow() {
        let selection = HexSelection(anchor: 16, active: 31)

        let spans = HexSelectionSpans.spans(
            for: 1,
            bytesPerRow: 16,
            fileSize: 32,
            selection: selection
        )

        XCTAssertEqual(spans?.count, 1)
        XCTAssertEqual(spans?[0].startColumn, 0)
        XCTAssertEqual(spans?[0].endColumn, 15)
    }

    func testSpansReturnsNilWhenNoOverlap() {
        let selection = HexSelection(anchor: 0, active: 3)

        let spans = HexSelectionSpans.spans(
            for: 1,
            bytesPerRow: 16,
            fileSize: 32,
            selection: selection
        )

        XCTAssertNil(spans)
    }

    func testSpansReturnsNilWhenSelectionIsNil() {
        let spans = HexSelectionSpans.spans(
            for: 0,
            bytesPerRow: 16,
            fileSize: 32,
            selection: nil
        )

        XCTAssertNil(spans)
    }
}
