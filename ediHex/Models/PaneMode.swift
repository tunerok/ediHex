//
//  PaneMode.swift
//  ediHex
//

import Foundation

enum PaneMode {
    case document
    case comparison(left: HexDocument, right: HexDocument)
}
