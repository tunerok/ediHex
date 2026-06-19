//
//  TerminalByteSampler.swift
//  HexMac
//

import Foundation

enum TerminalByteSampler {
    static func collect(
        from spec: TerminalRangeSpec,
        flags: TerminalSamplingFlags,
        bytesProvider: (Range<Int>) -> [UInt8]
    ) -> [UInt8] {
        var bytes: [UInt8] = []
        bytes.reserveCapacity(spec.totalRawByteCount)

        for segment in spec.segments {
            bytes.append(contentsOf: bytesProvider(segment))
        }

        return apply(flags: flags, to: bytes)
    }

    static func apply(flags: TerminalSamplingFlags, to bytes: [UInt8]) -> [UInt8] {
        var filtered = bytes

        if let mask = flags.mask {
            if let eq = flags.eq {
                filtered = filtered.filter { ($0 & mask) == eq }
            } else {
                filtered = filtered.filter { ($0 & mask) != 0 }
            }
        }

        if let every = flags.every, every > 1 {
            filtered = filtered.enumerated().compactMap { index, byte in
                (index % every) == 0 ? byte : nil
            }
        }

        return filtered
    }
}
