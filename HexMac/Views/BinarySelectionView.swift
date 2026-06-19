//
//  BinarySelectionView.swift
//  HexMac
//

import AppKit
import SwiftUI

struct BinarySelectionView: View {
    let selectionStart: Int
    let selectionEnd: Int
    let byteCount: Int
    let bytesProvider: (Range<Int>) -> [UInt8]
    let onClose: () -> Void

    @State private var integerInterpretations: [BinaryIntegerInterpretation] = []
    @State private var copyAlertMessage: String?

    private var displayedByteCount: Int {
        BinarySelectionFormatter.displayedByteCount(for: byteCount)
    }

    private var lineCount: Int {
        BinarySelectionFormatter.lineCount(for: displayedByteCount)
    }

    private var showsTruncationNotice: Bool {
        byteCount > BinarySelectionFormatter.maxDisplayBytes
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "Binary Representation"))
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text(
                    String(
                        localized: "Selection: 0x\(HexFormatter.offsetString(for: selectionStart)) – 0x\(HexFormatter.offsetString(for: selectionEnd))"
                    )
                )
                Text(
                    String(
                        localized: "\(byteCount) bytes",
                        comment: "Binary view byte count"
                    )
                )
            }
            .foregroundStyle(.secondary)

            if showsTruncationNotice {
                Text(
                    String(
                        localized: "Showing the first \(BinarySelectionFormatter.maxDisplayBytes) bytes of \(byteCount).",
                        comment: "Binary view truncation notice"
                    )
                )
                .font(.callout)
                .foregroundStyle(.orange)
            }

            if !integerInterpretations.isEmpty {
                Form {
                    Section(String(localized: "As integer")) {
                        ForEach(integerInterpretations) { interpretation in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(interpretation.endianness)
                                    .font(.headline)

                                Text(interpretation.decimalValue)
                                    .font(.body.monospaced())
                                    .textSelection(.enabled)

                                Text(interpretation.binaryText)
                                    .font(.body.monospaced())
                                    .textSelection(.enabled)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .formStyle(.grouped)
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(0..<lineCount, id: \.self) { lineIndex in
                        Text(formattedLine(at: lineIndex))
                            .font(.body.monospaced())
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack {
                Button(String(localized: "Copy")) {
                    copyToPasteboard()
                }

                Spacer()

                Button(String(localized: "Close")) {
                    onClose()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(minWidth: 560, idealWidth: 720, minHeight: 420, idealHeight: 560)
        .onAppear {
            loadIntegerInterpretations()
        }
        .alert(
            String(localized: "Copy Failed"),
            isPresented: Binding(
                get: { copyAlertMessage != nil },
                set: { if !$0 { copyAlertMessage = nil } }
            )
        ) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            Text(copyAlertMessage ?? "")
        }
    }

    private func formattedLine(at lineIndex: Int) -> String {
        let relativeRange = BinarySelectionFormatter.relativeLineRange(
            for: lineIndex,
            totalByteCount: displayedByteCount
        )
        let absoluteRange = (selectionStart + relativeRange.lowerBound)..<(selectionStart + relativeRange.upperBound)
        let bytes = bytesProvider(absoluteRange)
        return BinarySelectionFormatter.formattedLine(
            bytes: bytes,
            lineStartOffset: absoluteRange.lowerBound
        )
    }

    private func loadIntegerInterpretations() {
        guard byteCount <= 8 else {
            integerInterpretations = []
            return
        }

        let bytes = bytesProvider(selectionStart..<(selectionStart + byteCount))
        integerInterpretations = BinarySelectionFormatter.integerInterpretations(for: bytes)
    }

    private func copyToPasteboard() {
        let copyByteCount = min(byteCount, BinarySelectionFormatter.maxCopyBytes)
        guard copyByteCount == byteCount else {
            copyAlertMessage = String(
                localized: "Selection is too large to copy. Maximum size is \(BinarySelectionFormatter.maxCopyBytes) bytes."
            )
            return
        }

        let text = BinarySelectionFormatter.fullText(
            selectionStart: selectionStart,
            byteCount: copyByteCount,
            bytesProvider: bytesProvider
        )
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

#Preview {
    BinarySelectionView(
        selectionStart: 0,
        selectionEnd: 2,
        byteCount: 3,
        bytesProvider: { _ in [0x48, 0x65, 0x6C] },
        onClose: {}
    )
}
