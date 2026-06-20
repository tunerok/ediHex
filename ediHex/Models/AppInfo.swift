//
//  AppInfo.swift
//  ediHex
//

import Foundation

enum AppInfo {
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1"
    }

    static let name = "ediHex"
    static let author = "tunerok(Artem Ashirov)"
    static let copyrightYear = "2026"
    static let repositoryURL = URL(string: "https://github.com/tunerok/edihex")!
}
