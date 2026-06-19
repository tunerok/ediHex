//
//  ByteCompareService.swift
//  HexMac
//

import Foundation

enum CompareSide {
    case left
    case right
}

enum DiffRegionKind: String, CaseIterable {
    case equal
    case deleted
    case added
    case changed

    var label: String { rawValue }
}

struct DiffEntry: Equatable {
    let offset: Int
    let leftByte: UInt8?
    let rightByte: UInt8?
    let kind: DiffRegionKind
}

struct CompareDiffMap: Equatable {
    let bucketCount: Int
    let totalBytes: Int
    let leftKinds: [DiffRegionKind]
    let rightKinds: [DiffRegionKind]

    func bucketStartOffset(for index: Int) -> Int {
        guard bucketCount > 0, totalBytes > 0 else { return 0 }
        return (index * totalBytes) / bucketCount
    }
}

enum CompareDiffExportFormat {
    case text
    case csv

    var fileExtension: String {
        switch self {
        case .text: "txt"
        case .csv: "csv"
        }
    }
}

enum ByteCompareService {
    static let defaultBucketCount = 400

    static func highlightColor(
        at offset: Int,
        side: CompareSide,
        leftSize: Int,
        rightSize: Int,
        leftByte: UInt8?,
        rightByte: UInt8?
    ) -> HighlightColor? {
        switch diffKind(
            leftSize: leftSize,
            rightSize: rightSize,
            leftByte: leftByte,
            rightByte: rightByte,
            side: side
        ) {
        case .deleted:
            return .red
        case .added:
            return .green
        case .changed:
            return .yellow
        case .equal, .none:
            return nil
        }
    }

    static func diffKind(
        leftSize: Int,
        rightSize: Int,
        leftByte: UInt8?,
        rightByte: UInt8?,
        side: CompareSide
    ) -> DiffRegionKind? {
        let hasLeft = leftByte != nil
        let hasRight = rightByte != nil

        switch (hasLeft, hasRight) {
        case (true, false):
            return side == .left ? .deleted : nil
        case (false, true):
            return side == .right ? .added : nil
        case (true, true):
            guard let leftByte, let rightByte, leftByte != rightByte else { return .equal }
            return .changed
        case (false, false):
            return .equal
        }
    }

    static func diffEntry(
        at offset: Int,
        leftSize: Int,
        rightSize: Int,
        leftByte: UInt8?,
        rightByte: UInt8?
    ) -> DiffEntry? {
        let hasLeft = offset < leftSize
        let hasRight = offset < rightSize

        switch (hasLeft, hasRight) {
        case (true, false):
            return DiffEntry(offset: offset, leftByte: leftByte, rightByte: nil, kind: .deleted)
        case (false, true):
            return DiffEntry(offset: offset, leftByte: nil, rightByte: rightByte, kind: .added)
        case (true, true):
            guard let leftByte, let rightByte else { return nil }
            guard leftByte != rightByte else { return nil }
            return DiffEntry(offset: offset, leftByte: leftByte, rightByte: rightByte, kind: .changed)
        case (false, false):
            return nil
        }
    }

    static func collectDiffEntries(
        leftSize: Int,
        rightSize: Int,
        leftByte: (Int) -> UInt8?,
        rightByte: (Int) -> UInt8?
    ) -> [DiffEntry] {
        let total = max(leftSize, rightSize)
        guard total > 0 else { return [] }

        var entries: [DiffEntry] = []
        entries.reserveCapacity(min(total, 1024))

        for offset in 0..<total {
            let left = offset < leftSize ? leftByte(offset) : nil
            let right = offset < rightSize ? rightByte(offset) : nil
            if let entry = diffEntry(
                at: offset,
                leftSize: leftSize,
                rightSize: rightSize,
                leftByte: left,
                rightByte: right
            ) {
                entries.append(entry)
            }
        }
        return entries
    }

    static func buildDiffMap(
        leftSize: Int,
        rightSize: Int,
        leftByte: (Int) -> UInt8?,
        rightByte: (Int) -> UInt8?,
        bucketCount: Int = defaultBucketCount
    ) -> CompareDiffMap {
        let total = max(leftSize, rightSize)
        let count = max(1, bucketCount)
        var leftKinds = Array(repeating: DiffRegionKind.equal, count: count)
        var rightKinds = Array(repeating: DiffRegionKind.equal, count: count)

        guard total > 0 else {
            return CompareDiffMap(
                bucketCount: count,
                totalBytes: 0,
                leftKinds: leftKinds,
                rightKinds: rightKinds
            )
        }

        for bucketIndex in 0..<count {
            let start = (bucketIndex * total) / count
            let end = ((bucketIndex + 1) * total) / count
            guard start < end else { continue }

            var leftBucketKind = DiffRegionKind.equal
            var rightBucketKind = DiffRegionKind.equal

            for offset in start..<end {
                let left = offset < leftSize ? leftByte(offset) : nil
                let right = offset < rightSize ? rightByte(offset) : nil

                if let kind = diffKind(
                    leftSize: leftSize,
                    rightSize: rightSize,
                    leftByte: left,
                    rightByte: right,
                    side: .left
                ), kind != .equal {
                    leftBucketKind = maxPriority(leftBucketKind, kind)
                }
                if let kind = diffKind(
                    leftSize: leftSize,
                    rightSize: rightSize,
                    leftByte: left,
                    rightByte: right,
                    side: .right
                ), kind != .equal {
                    rightBucketKind = maxPriority(rightBucketKind, kind)
                }
            }

            leftKinds[bucketIndex] = leftBucketKind
            rightKinds[bucketIndex] = rightBucketKind
        }

        return CompareDiffMap(
            bucketCount: count,
            totalBytes: total,
            leftKinds: leftKinds,
            rightKinds: rightKinds
        )
    }

    static func formatTextReport(
        entries: [DiffEntry],
        leftName: String,
        rightName: String
    ) -> String {
        var lines: [String] = [
            "HexMac Compare Report",
            "Left:  \(leftName)",
            "Right: \(rightName)",
            "Differences: \(entries.count)",
            ""
        ]

        if entries.isEmpty {
            lines.append("Files are identical.")
            return lines.joined(separator: "\n")
        }

        var index = 0
        while index < entries.count {
            let entry = entries[index]
            var end = entry.offset
            var leftByte = entry.leftByte
            var rightByte = entry.rightByte
            var next = index + 1

            while next < entries.count,
                  entries[next].kind == entry.kind,
                  entries[next].offset == end + 1 {
                end = entries[next].offset
                leftByte = entries[next].leftByte ?? leftByte
                rightByte = entries[next].rightByte ?? rightByte
                next += 1
            }

            let startText = HexFormatter.offsetString(for: entry.offset)
            if entry.offset == end {
                lines.append(formatTextLine(
                    offset: startText,
                    kind: entry.kind,
                    leftByte: leftByte,
                    rightByte: rightByte
                ))
            } else {
                let endText = HexFormatter.offsetString(for: end)
                lines.append(formatTextLine(
                    offset: "\(startText)-\(endText)",
                    kind: entry.kind,
                    leftByte: leftByte,
                    rightByte: rightByte
                ))
            }
            index = next
        }

        return lines.joined(separator: "\n")
    }

    static func formatCSV(entries: [DiffEntry]) -> String {
        var lines = ["offset,kind,left_hex,right_hex"]
        lines.reserveCapacity(entries.count + 1)

        for entry in entries {
            let offset = HexFormatter.offsetString(for: entry.offset)
            let left = entry.leftByte.map { HexFormatter.hexPair(for: $0) } ?? ""
            let right = entry.rightByte.map { HexFormatter.hexPair(for: $0) } ?? ""
            lines.append("\(offset),\(entry.kind.rawValue),\(left),\(right)")
        }
        return lines.joined(separator: "\n")
    }

    static func byte(at offset: Int, in size: Int, provider: (Int) -> UInt8?) -> UInt8? {
        guard offset < size else { return nil }
        return provider(offset)
    }

    private static func maxPriority(_ current: DiffRegionKind, _ candidate: DiffRegionKind) -> DiffRegionKind {
        priority(for: candidate) > priority(for: current) ? candidate : current
    }

    private static func priority(for kind: DiffRegionKind) -> Int {
        switch kind {
        case .changed: 3
        case .deleted, .added: 2
        case .equal: 0
        }
    }

    private static func formatTextLine(
        offset: String,
        kind: DiffRegionKind,
        leftByte: UInt8?,
        rightByte: UInt8?
    ) -> String {
        let left = leftByte.map { HexFormatter.hexPair(for: $0) } ?? "--"
        let right = rightByte.map { HexFormatter.hexPair(for: $0) } ?? "--"
        return "0x\(offset)  \(kind.label)  \(left) -> \(right)"
    }
}
