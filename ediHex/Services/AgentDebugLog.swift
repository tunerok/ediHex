//
//  AgentDebugLog.swift
//  ediHex
//
//  Enable in Xcode: Build Settings → Active Compilation Conditions → DEBUG_VIEW
//

import Foundation

#if DEBUG_VIEW
enum AgentDebugLog {
    private static let logPath = "/Users/artem/Documents/hex_mac/HexMac/.cursor/debug-248a76.log"
    private static let ingestURL = URL(
        string: "http://127.0.0.1:7333/ingest/215f39d8-f259-4a52-9b04-f06ccb877158"
    )!
    private static let sessionId = "248a76"

    static func write(
        hypothesisId: String,
        location: String,
        message: String,
        data: [String: Any],
        runId: String = "pre-fix"
    ) {
        var payload: [String: Any] = [
            "sessionId": sessionId,
            "runId": runId,
            "hypothesisId": hypothesisId,
            "location": location,
            "message": message,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000),
            "data": data,
        ]

        guard JSONSerialization.isValidJSONObject(payload),
              let json = try? JSONSerialization.data(withJSONObject: payload),
              let line = String(data: json, encoding: .utf8) else {
            print("[agent-debug] JSON encode failed at \(location)")
            return
        }

        print("[agent-debug] \(line)")
        postToIngest(json)
        appendLine(line, to: logPath)
    }

    private static func postToIngest(_ json: Data) {
        var request = URLRequest(url: ingestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(sessionId, forHTTPHeaderField: "X-Debug-Session-Id")
        request.httpBody = json

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error {
                print("[agent-debug] ingest POST failed: \(error.localizedDescription)")
                return
            }
            if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
                print("[agent-debug] ingest POST status \(http.statusCode)")
            }
        }.resume()
    }

    private static func appendLine(_ line: String, to path: String) {
        let url = URL(fileURLWithPath: path)
        let directory = url.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            return
        }

        guard let lineData = (line + "\n").data(using: .utf8) else { return }

        if FileManager.default.fileExists(atPath: path) {
            guard let handle = try? FileHandle(forWritingTo: url) else { return }
            defer { try? handle.close() }
            try? handle.seekToEnd()
            try? handle.write(contentsOf: lineData)
        } else {
            FileManager.default.createFile(atPath: path, contents: lineData)
        }
    }
}
#else
enum AgentDebugLog {
    static func write(
        hypothesisId: String,
        location: String,
        message: String,
        data: [String: Any],
        runId: String = "pre-fix"
    ) {}
}
#endif
