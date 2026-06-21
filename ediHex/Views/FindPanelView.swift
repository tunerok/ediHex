//
//  FindPanelView.swift
//  ediHex
//

import SwiftUI

struct FindPanelView: View {
    @Bindable var pane: DocumentPaneViewModel
    let onClose: () -> Void

    @State private var searchText = ""
    @State private var isHexMode = true
    @State private var isASCIIMode = false
    @State private var searchEntireFile = true
    @State private var searchDown = true
    @State private var searchUp = false
    @State private var statusMessage = ""
    @State private var hexValidationError: HexParseError?

    private var patternMode: FindPatternMode {
        isHexMode ? .hex : .ascii
    }

    private var searchDirection: FindDirection {
        searchUp ? .up : .down
    }

    private var isInputValid: Bool {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if isHexMode {
            return hexValidationError == nil
        }
        return true
    }

    private var progressText: String {
        String(
            localized: "Scanning… \(String(format: "%.1f", pane.findProgress * 100))%",
            comment: "Find scan progress"
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "Find"))
                .font(.title2)

            TextField(String(localized: "Search pattern"), text: $searchText)
                .textFieldStyle(.roundedBorder)
                .font(isHexMode ? .body.monospaced() : .body)
                .disabled(pane.isFindLoading)
                .onChange(of: searchText) { _, _ in
                    validateInput()
                }
                .onChange(of: isHexMode) { _, _ in
                    validateInput()
                }

            if let hexValidationError, isHexMode {
                Text(hexValidationError.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Form {
                Toggle(String(localized: "Hex"), isOn: $isHexMode)
                    .disabled(pane.isFindLoading)
                    .onChange(of: isHexMode) { _, newValue in
                        if newValue {
                            isASCIIMode = false
                        } else if !isASCIIMode {
                            isHexMode = true
                        }
                    }

                Toggle(String(localized: "ASCII"), isOn: $isASCIIMode)
                    .disabled(pane.isFindLoading)
                    .onChange(of: isASCIIMode) { _, newValue in
                        if newValue {
                            isHexMode = false
                        } else if !isHexMode {
                            isASCIIMode = true
                        }
                    }

                Toggle(String(localized: "Search entire file"), isOn: $searchEntireFile)
                    .disabled(pane.isFindLoading)

                Toggle(String(localized: "Search down"), isOn: $searchDown)
                    .disabled(searchEntireFile || pane.isFindLoading)
                    .onChange(of: searchDown) { _, newValue in
                        if newValue {
                            searchUp = false
                        } else if !searchUp, !searchEntireFile {
                            searchDown = true
                        }
                    }

                Toggle(String(localized: "Search up"), isOn: $searchUp)
                    .disabled(searchEntireFile || pane.isFindLoading)
                    .onChange(of: searchUp) { _, newValue in
                        if newValue {
                            searchDown = false
                        } else if !searchDown, !searchEntireFile {
                            searchUp = true
                        }
                    }
            }
            .formStyle(.grouped)

            if pane.isFindLoading {
                VStack(spacing: 8) {
                    ProgressView(value: max(pane.findProgress, 0.001))
                    Text(progressText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .foregroundStyle(pane.findSession?.hasMatches == true ? .primary : .secondary)
            }

            HStack {
                Button(String(localized: "Previous")) {
                    performPreviousMatch()
                }
                .disabled(pane.isFindLoading || (pane.findSession?.currentIndex ?? 0) <= 0)

                Button(String(localized: "Next")) {
                    performNextMatch()
                }
                .disabled(
                    pane.isFindLoading
                        || (pane.findSession?.currentIndex ?? -1) + 1 >= (pane.findSession?.matches.count ?? 0)
                )

                Spacer()

                Button(String(localized: "Close"), action: onClose)
                    .keyboardShortcut(.cancelAction)

                Button(String(localized: "Find Next")) {
                    performFindNext()
                }
                .disabled(!isInputValid || pane.isFindLoading)

                if pane.isFindLoading {
                    Button(String(localized: "Stop")) {
                        stopSearch()
                    }
                    .keyboardShortcut(.defaultAction)
                } else {
                    Button(String(localized: "Find")) {
                        performFind()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isInputValid)
                }
            }
        }
        .padding(20)
        .frame(width: 480)
        .onAppear {
            restoreFromSession()
            validateInput()
            updateStatusFromSession()
        }
        .onChange(of: pane.findSession) { _, _ in
            updateStatusFromSession()
        }
        .onChange(of: pane.isFindLoading) { _, _ in
            updateStatusFromSession()
        }
        .onChange(of: pane.findProgress) { _, _ in
            updateStatusFromSession()
        }
    }

    private func restoreFromSession() {
        guard let session = pane.findSession else { return }

        searchText = session.queryText
        isHexMode = session.mode == .hex
        isASCIIMode = session.mode == .ascii
        searchEntireFile = session.entireFile
        searchDown = session.direction == .down
        searchUp = session.direction == .up
    }

    private func validateInput() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isHexMode else {
            hexValidationError = trimmed.isEmpty ? .empty : nil
            return
        }

        if trimmed.isEmpty {
            hexValidationError = .empty
            return
        }

        switch BytePatternSearch.parseHex(trimmed) {
        case .success:
            hexValidationError = nil
        case .failure(let error):
            hexValidationError = error
        }
    }

    private func performFind() {
        statusMessage = ""
        pane.startFind(
            input: searchText,
            mode: patternMode,
            entireFile: searchEntireFile,
            direction: searchDirection
        )
    }

    private func performFindNext() {
        if pane.findSession == nil {
            performFind()
            return
        }

        pane.startFindNext()
    }

    private func stopSearch() {
        pane.stopFind()
        if let session = pane.findSession, session.hasMatches {
            updateStatusFromSession()
        } else {
            statusMessage = String(localized: "Stopped", comment: "Find scan stopped by user")
        }
    }

    private func performPreviousMatch() {
        let result = pane.findPreviousMatch()
        updateStatus(for: result, keepStatusOnFailure: true)
    }

    private func performNextMatch() {
        let result = pane.findNextMatch()
        updateStatus(for: result, keepStatusOnFailure: true)
    }

    private func updateStatus(for result: FindResult, keepStatusOnFailure: Bool = false) {
        switch result {
        case .found:
            updateStatusFromSession()
        case .notFound:
            if keepStatusOnFailure {
                updateStatusFromSession()
            } else if !pane.isFindLoading {
                statusMessage = String(localized: "Not found")
            }
        }
    }

    private func updateStatusFromSession() {
        if pane.isFindLoading, pane.findSession == nil {
            statusMessage = progressText
            return
        }

        if let session = pane.findSession,
           let status = session.statusText(isScanning: pane.isFindLoading, progress: pane.findProgress) {
            statusMessage = status
        } else if pane.findSession != nil, !pane.isFindLoading {
            statusMessage = String(localized: "Not found")
        } else if pane.isFindLoading {
            statusMessage = progressText
        }
    }
}

#if DEBUG
#Preview {
    FindPanelView(pane: DocumentPaneViewModel()) {}
}
#endif
