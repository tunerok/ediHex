//
//  HistogramView.swift
//  HexMac
//

import AppKit
import Charts
import SwiftUI
import UniformTypeIdentifiers

struct HistogramView: View {
    let fileName: String
    let title: String
    let byteCount: Int
    let counts: [Int]
    let onClose: () -> Void

    private enum ExportFormat {
        case png
        case jpeg

        var fileExtension: String {
            switch self {
            case .png:
                "png"
            case .jpeg:
                "jpg"
            }
        }

        var contentType: UTType {
            switch self {
            case .png:
                .png
            case .jpeg:
                .jpeg
            }
        }
    }

    private var chartData: [HistogramByteCount] {
        counts.enumerated().map { HistogramByteCount(byte: $0.offset, count: $0.element) }
    }

    private var topEntries: [(byte: Int, count: Int)] {
        Array(HistogramBuilder.nonZeroEntries(in: counts).prefix(16))
    }

    private var summaryText: String {
        String(
            localized: "\(byteCount) bytes, \(HistogramBuilder.nonZeroEntries(in: counts).count) unique values",
            comment: "Histogram summary"
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                histogramContent
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            HStack {
                Button(String(localized: "Save as PNG…")) {
                    saveHistogram(as: .png)
                }

                Button(String(localized: "Save as JPEG…")) {
                    saveHistogram(as: .jpeg)
                }

                Spacer()

                Button(String(localized: "Close"), action: onClose)
                    .keyboardShortcut(.cancelAction)
            }
            .padding(20)
        }
        .frame(width: 640)
        .frame(minHeight: 420, idealHeight: 560, maxHeight: 720)
    }

    private var histogramContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "Byte Histogram"))
                .font(.title2)

            Text(fileName)
                .font(.title3)
                .textSelection(.enabled)

            Text(title)
                .font(.headline)

            Text(summaryText)
                .foregroundStyle(.secondary)

            histogramChart
                .frame(height: 280)

            if !topEntries.isEmpty {
                topEntriesList
            }
        }
    }

    private var histogramChart: some View {
        Chart(chartData) { entry in
            BarMark(
                x: .value("Byte", entry.byte),
                y: .value("Count", entry.count)
            )
            .foregroundStyle(.blue.gradient)
        }
        .chartXAxisLabel(String(localized: "Byte value (hex)"))
        .chartYAxisLabel(String(localized: "Count"))
        .chartXScale(domain: 0...255)
    }

    private var topEntriesList: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "Most frequent"))
                .font(.headline)

            ForEach(topEntries, id: \.byte) { entry in
                HStack {
                    Text("0x\(String(format: "%02X", entry.byte))")
                        .font(.body.monospaced())
                        .frame(width: 40, alignment: .leading)
                    Text("\(entry.count)")
                        .font(.body.monospaced())
                    Spacer()
                    Text(percentage(for: entry.count))
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func percentage(for count: Int) -> String {
        guard byteCount > 0 else { return "0%" }
        let value = Double(count) / Double(byteCount) * 100
        return String(format: "%.1f%%", value)
    }

    private var defaultExportBaseName: String {
        let sanitized = fileName
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        return sanitized.isEmpty ? "histogram" : "\(sanitized)-histogram"
    }

    @MainActor
    private func saveHistogram(as format: ExportFormat) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [format.contentType]
        panel.nameFieldStringValue = "\(defaultExportBaseName).\(format.fileExtension)"
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let exportView = HistogramExportView(
            fileName: fileName,
            title: title,
            summaryText: summaryText,
            chartData: chartData,
            topEntries: topEntries,
            byteCount: byteCount
        )

        let renderer = ImageRenderer(content: exportView)
        renderer.proposedSize = ProposedViewSize(width: 1200, height: 900)

        guard let nsImage = renderer.nsImage,
              let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return
        }

        let imageData: Data?
        switch format {
        case .png:
            imageData = bitmap.representation(using: .png, properties: [:])
        case .jpeg:
            imageData = bitmap.representation(
                using: .jpeg,
                properties: [.compressionFactor: 0.9]
            )
        }

        guard let imageData else { return }

        do {
            try imageData.write(to: url, options: .atomic)
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }
}

private struct HistogramByteCount: Identifiable {
    let byte: Int
    let count: Int
    var id: Int { byte }
}

private struct HistogramExportView: View {
    let fileName: String
    let title: String
    let summaryText: String
    let chartData: [HistogramByteCount]
    let topEntries: [(byte: Int, count: Int)]
    let byteCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(String(localized: "Byte Histogram"))
                .font(.largeTitle.bold())

            Text(fileName)
                .font(.title.bold())
                .textSelection(.enabled)

            Text(title)
                .font(.title2)

            Text(summaryText)
                .font(.title3)
                .foregroundStyle(.secondary)

            Chart(chartData) { entry in
                BarMark(
                    x: .value("Byte", entry.byte),
                    y: .value("Count", entry.count)
                )
                .foregroundStyle(.blue.gradient)
            }
            .chartXAxisLabel(String(localized: "Byte value (hex)"))
            .chartYAxisLabel(String(localized: "Count"))
            .chartXScale(domain: 0...255)
            .frame(height: 420)

            if !topEntries.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Most frequent"))
                        .font(.title3.bold())

                    ForEach(topEntries, id: \.byte) { entry in
                        HStack {
                            Text("0x\(String(format: "%02X", entry.byte))")
                                .font(.body.monospaced())
                                .frame(width: 48, alignment: .leading)
                            Text("\(entry.count)")
                                .font(.body.monospaced())
                            Spacer()
                            Text(percentage(for: entry.count))
                                .font(.body.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(32)
        .frame(width: 1200, alignment: .leading)
        .background(Color.white)
    }

    private func percentage(for count: Int) -> String {
        guard byteCount > 0 else { return "0%" }
        let value = Double(count) / Double(byteCount) * 100
        return String(format: "%.1f%%", value)
    }
}

#Preview {
    HistogramView(
        fileName: "firmware.bin",
        title: "Entire file",
        byteCount: 256,
        counts: (0..<256).map { $0 == 0x00 ? 100 : $0 == 0xFF ? 50 : 1 },
        onClose: {}
    )
}
