//
//  CompareHexGridView.swift
//  ediHex
//

import AppKit
import SwiftUI

struct CompareHexGridView: View {
    private static let scrollbarColumnWidth: CGFloat = 16
    private static let horizontalScrollbarPadding: CGFloat = 6

    private static func horizontalScrollbarReserve(needsHorizontalScroll: Bool) -> CGFloat {
        guard needsHorizontalScroll else { return 0 }
        return NSScroller.scrollerWidth(for: .regular, scrollerStyle: .overlay)
            + horizontalScrollbarPadding
    }

    @Bindable var pane: DocumentPaneViewModel
    @Binding var visibleRowRange: ClosedRange<Int>
    let onActivate: () -> Void

    @State private var firstVisibleRow = 0
    @State private var minimapRowRange: ClosedRange<Int> = 0...0
    @State private var minimapRangeDebounceTask: Task<Void, Never>?

    private var scrollTargetRow: Int? {
        guard let target = pane.scrollTargetOffset, pane.bytesPerRow.rawValue > 0 else { return nil }
        return target / pane.bytesPerRow.rawValue
    }

    #if DEBUG_VIEW
    private struct LayoutProbe: View {
        let size: CGSize
        let pane: DocumentPaneViewModel
        let firstVisibleRow: Int

        var body: some View {
            Color.clear
                .frame(width: 0, height: 0)
                .onAppear { log() }
                .onChange(of: size) { _, _ in log() }
                .onChange(of: firstVisibleRow) { _, _ in log() }
        }

        private func log() {
            CompareHexGridView.logCompareLayout(size: size, pane: pane, firstVisibleRow: firstVisibleRow)
        }
    }
    #endif

    var body: some View {
        let rowDataRevision = pane.comparisonRowRevision

        return GeometryReader { geometry in
            let gridHeight = verticalScrollHeight(in: geometry)
            let dataAreaWidth = geometry.size.width
                - (HexGridLayout.offsetColumnWidth + HexGridLayout.contentPadding)
                - (Self.scrollbarColumnWidth + HexGridLayout.contentPadding)
            let pairedWidth = Self.pairedDataWidth(bytesPerRow: pane.bytesPerRow.rawValue)
            let needsHorizontalScroll = pairedWidth > dataAreaWidth
            let horizontalScrollReserve = Self.horizontalScrollbarReserve(
                needsHorizontalScroll: needsHorizontalScroll
            )
            let viewportHeight = max(0, gridHeight - horizontalScrollReserve)
            let visibleRowCount = max(
                1,
                Int((viewportHeight - HexGridLayout.contentPadding) / HexGridLayout.rowHeight)
            )

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    HexOffsetHeaderView()
                    Divider()
                    HexOffsetColumnView(
                        firstVisibleRow: firstVisibleRow,
                        rowCount: pane.rowCount,
                        bytesPerRow: pane.bytesPerRow.rawValue,
                        visibleRowCount: visibleRowCount,
                        height: viewportHeight
                    )
                }
                .padding(.leading, HexGridLayout.contentPadding)
                .frame(width: HexGridLayout.offsetColumnWidth + HexGridLayout.contentPadding, alignment: .leading)

                ScrollView(.horizontal) {
                    VStack(alignment: .leading, spacing: 0) {
                        pairedHeaders
                        Divider()
                        HexViewportScrollView(
                            firstVisibleRow: $firstVisibleRow,
                            rowCount: pane.rowCount,
                            bytesPerRow: pane.bytesPerRow.rawValue,
                            visibleRowCount: visibleRowCount,
                            contentWidth: Self.pairedDataWidth(bytesPerRow: pane.bytesPerRow.rawValue),
                            scrollTargetRow: scrollTargetRow,
                            scrollRevealOffset: pane.scrollRevealOffset,
                            scrollAnchor: .top,
                            linkedScrollRow: nil,
                            onVisibleRowChanged: nil,
                            onVisibleRowRangeChanged: { range in
                                scheduleMinimapRangeUpdate(range)
                            },
                            onPrefetchRange: { range in
                                guard !range.isEmpty else { return }
                                let midpoint = (range.lowerBound + range.upperBound) / 2
                                Task {
                                    await pane.loadComparisonRows(
                                        around: midpoint,
                                        radius: HexScrollWindow.prefetchMargin,
                                        cancelPrevious: false
                                    )
                                }
                            },
                            onEnsureVisibleRowsLoaded: { range in
                                guard !range.isEmpty else { return }
                                let midpoint = (range.lowerBound + range.upperBound) / 2
                                let radius = max(
                                    HexScrollWindow.prefetchMargin,
                                    (range.upperBound - range.lowerBound) / 2 + 1
                                )
                                Task {
                                    await pane.loadComparisonRows(
                                        around: midpoint,
                                        radius: radius,
                                        cancelPrevious: false
                                    )
                                }
                            },
                            onScrollTargetHandled: {
                                pane.clearScrollTarget()
                            },
                            onScrollRevealHandled: {
                                pane.clearScrollReveal()
                            },
                            rowContent: { rowIndex in
                                pairedRow(rowIndex: rowIndex, rowDataRevision: rowDataRevision)
                            },
                            overlay: { firstVisibleRow in
                                selectionOverlay(firstVisibleRow: firstVisibleRow)
                            }
                        )
                        .frame(height: viewportHeight)
                        if horizontalScrollReserve > 0 {
                            Color.clear
                                .frame(height: horizontalScrollReserve)
                        }
                    }
                    .frame(minWidth: Self.pairedDataWidth(bytesPerRow: pane.bytesPerRow.rawValue))
                    .padding(.trailing, HexGridLayout.contentPadding)
                }

                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: HexGridLayout.headerTotalHeight)
                    HexVerticalScrollbar(
                        firstVisibleRow: $firstVisibleRow,
                        rowCount: pane.rowCount,
                        visibleRowCount: visibleRowCount
                    )
                    .frame(height: viewportHeight)
                }
                .frame(width: Self.scrollbarColumnWidth)
                .padding(.trailing, HexGridLayout.contentPadding)
            }
            .background {
                #if DEBUG_VIEW
                LayoutProbe(size: geometry.size, pane: pane, firstVisibleRow: firstVisibleRow)
                #endif
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            #if DEBUG_VIEW
            // #region agent log
            AgentDebugLog.write(
                hypothesisId: "startup",
                location: "CompareHexGridView.swift:onAppear",
                message: "compare grid appeared",
                data: ["rowCount": pane.rowCount, "fileSize": pane.fileSize]
            )
            // #endregion
            #endif
            minimapRowRange = visibleRowRange
        }
        .onDisappear {
            minimapRangeDebounceTask?.cancel()
        }
        .onChange(of: minimapRowRange) { _, newValue in
            visibleRowRange = newValue
        }
    }

    private var pairedHeaders: some View {
        HStack(spacing: 0) {
            HexGridHeaderView(bytesPerRow: pane.bytesPerRow.rawValue, showsOffsetColumn: false)
            panelSeparator
            HexGridHeaderView(bytesPerRow: pane.bytesPerRow.rawValue, showsOffsetColumn: false)
        }
    }

    private func pairedRow(rowIndex: Int, rowDataRevision: Int) -> some View {
        let context = pane.comparisonRowContext(for: rowIndex)

        #if DEBUG_VIEW
        // #region agent log
        if rowIndex == pane.rowCount - 1 {
            AgentDebugLog.write(
                hypothesisId: "C,D",
                location: "CompareHexGridView.swift:pairedRow",
                message: "compare last row bytes",
                data: [
                    "rowIndex": rowIndex,
                    "rowCount": pane.rowCount,
                    "leftByteCount": context.leftBytes.count,
                    "rightByteCount": context.rightBytes.count,
                    "expectedByteCount": HexFormatter.byteCount(
                        forRow: rowIndex,
                        fileSize: pane.fileSize,
                        bytesPerRow: pane.bytesPerRow.rawValue
                    ),
                    "compareRowRevision": pane.compareRowRevision(for: rowIndex),
                    "leftFileSize": pane.comparisonFileSize(for: .left),
                    "rightFileSize": pane.comparisonFileSize(for: .right),
                ]
            )
        }
        // #endregion
        #endif

        return HStack(spacing: 0) {
            HexRowView(
                rowIndex: rowIndex,
                bytes: context.leftBytes,
                fileSize: pane.comparisonFileSize(for: .left),
                bytesPerRow: pane.bytesPerRow.rawValue,
                selection: pane.comparisonLeftSelection,
                editingOffset: nil,
                editingHexText: "",
                textEncoding: pane.textEncoding,
                diffHexSpans: context.leftDiffSpans,
                showsOffsetColumn: false
            )
            .equatable()

            panelSeparator

            HexRowView(
                rowIndex: rowIndex,
                bytes: context.rightBytes,
                fileSize: pane.comparisonFileSize(for: .right),
                bytesPerRow: pane.bytesPerRow.rawValue,
                selection: pane.comparisonRightSelection,
                editingOffset: nil,
                editingHexText: "",
                textEncoding: pane.textEncoding,
                diffHexSpans: context.rightDiffSpans,
                showsOffsetColumn: false
            )
            .equatable()
        }
        .frame(width: Self.pairedDataWidth(bytesPerRow: pane.bytesPerRow.rawValue), alignment: .leading)
        .id("\(rowIndex)-\(pane.bytesPerRow.rawValue)-\(rowDataRevision)-\(pane.compareRowRevision(for: rowIndex))")
    }

    private func scheduleMinimapRangeUpdate(_ range: ClosedRange<Int>) {
        minimapRangeDebounceTask?.cancel()
        minimapRangeDebounceTask = Task {
            try? await Task.sleep(for: .milliseconds(75))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                minimapRowRange = range
            }
        }
    }

    private func selectionOverlay(firstVisibleRow: Int) -> some View {
        let sideWidth = Self.sideContentWidth(bytesPerRow: pane.bytesPerRow.rawValue)

        return HStack(spacing: 0) {
            selectionHandlingView(
                side: .left,
                selection: pane.comparisonLeftSelection,
                width: sideWidth,
                firstVisibleRow: firstVisibleRow
            ) { offset, extending in
                onActivate()
                pane.beginComparisonSelection(at: offset, side: .left, extending: extending)
            } onUpdate: { offset in
                pane.updateComparisonSelection(to: offset, side: .left)
            } onEnd: { offset in
                pane.endComparisonSelection(at: offset, side: .left)
            } onCopy: {
                pane.copyComparisonSelection(side: .left)
            }

            panelSeparator

            selectionHandlingView(
                side: .right,
                selection: pane.comparisonRightSelection,
                width: sideWidth,
                firstVisibleRow: firstVisibleRow
            ) { offset, extending in
                onActivate()
                pane.beginComparisonSelection(at: offset, side: .right, extending: extending)
            } onUpdate: { offset in
                pane.updateComparisonSelection(to: offset, side: .right)
            } onEnd: { offset in
                pane.endComparisonSelection(at: offset, side: .right)
            } onCopy: {
                pane.copyComparisonSelection(side: .right)
            }
        }
    }

    private func selectionHandlingView(
        side: CompareSide,
        selection: HexSelection?,
        width: CGFloat,
        firstVisibleRow: Int,
        onBegin: @escaping (Int, Bool) -> Void,
        onUpdate: @escaping (Int) -> Void,
        onEnd: @escaping (Int) -> Void,
        onCopy: @escaping () -> Void
    ) -> some View {
        HexSelectionHandlingView(
            rowCount: pane.rowCount,
            fileSize: pane.fileSize,
            bytesPerRow: pane.bytesPerRow.rawValue,
            firstVisibleRow: firstVisibleRow,
            editingOffset: nil,
            selection: selection,
            isReadOnly: true,
            onBeginSelection: onBegin,
            onUpdateSelection: onUpdate,
            onEndSelection: onEnd,
            onMoveSelection: { direction, extending in
                onActivate()
                pane.moveComparisonSelection(direction: direction, extending: extending, side: side)
            },
            onHexDigit: { _ in },
            onBackspace: {},
            onCancelEdit: {},
            onAddHighlight: { _ in },
            onRemoveHighlight: { _ in },
            onCopySelection: onCopy,
            onClearSelection: {},
            onCalculateCRC: {},
            onCalculateHash: {},
            onShowBinary: {},
            onSaveSelectionAsBinary: {},
            onSaveSelectionAsHex: {},
            highlightColor: { pane.diffHighlight(at: $0, side: side) }
        )
        .frame(width: width, alignment: .leading)
        .clipped()
    }

    private var panelSeparator: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.35))
            .frame(width: 1)
    }

    #if DEBUG_VIEW
    fileprivate static func logCompareLayout(
        size: CGSize,
        pane: DocumentPaneViewModel,
        firstVisibleRow: Int
    ) {
        // #region agent log
        let geometry = size
        let usedHeight = HexGridLayout.headerContentHeight
            + HexGridLayout.headerBottomPadding
            + HexGridLayout.dividerWidth
        let gridHeight = max(0, geometry.height - usedHeight)
        let dataAreaWidth = geometry.width
            - (HexGridLayout.offsetColumnWidth + HexGridLayout.contentPadding)
            - (scrollbarColumnWidth + HexGridLayout.contentPadding)
        let pairedWidth = pairedDataWidth(bytesPerRow: pane.bytesPerRow.rawValue)
        let needsHorizontalScroll = pairedWidth > dataAreaWidth
        let horizontalScrollReserve = horizontalScrollbarReserve(needsHorizontalScroll: needsHorizontalScroll)
        let viewportHeight = max(0, gridHeight - horizontalScrollReserve)
        let visibleRowCount = max(
            1,
            Int((viewportHeight - HexGridLayout.contentPadding) / HexGridLayout.rowHeight)
        )
        let lastRow = pane.rowCount - 1
        let lastRowBottomY = HexGridLayout.contentPadding
            + CGFloat(max(0, lastRow - firstVisibleRow + 1)) * HexGridLayout.rowHeight
        AgentDebugLog.write(
            hypothesisId: "A,E,F",
            location: "CompareHexGridView.swift:layout",
            message: "compare grid layout",
            data: [
                "geometryWidth": Double(geometry.width),
                "geometryHeight": Double(geometry.height),
                "dataAreaWidth": Double(dataAreaWidth),
                "pairedDataWidth": Double(pairedWidth),
                "needsHorizontalScroll": needsHorizontalScroll,
                "horizontalScrollReserve": Double(horizontalScrollReserve),
                "gridHeight": Double(gridHeight),
                "viewportHeight": Double(viewportHeight),
                "visibleRowCount": visibleRowCount,
                "rowCount": pane.rowCount,
                "fileSize": pane.fileSize,
                "bytesPerRow": pane.bytesPerRow.rawValue,
                "firstVisibleRow": firstVisibleRow,
                "lastRowIndex": lastRow,
                "lastRowBottomYAtScroll": Double(lastRowBottomY),
                "viewportHeightDeficit": Double(lastRowBottomY - viewportHeight),
                "partialLastRowBytes": pane.fileSize % max(1, pane.bytesPerRow.rawValue),
            ]
        )
        // #endregion
    }
    #endif

    private func verticalScrollHeight(in geometry: GeometryProxy) -> CGFloat {
        let usedHeight = HexGridLayout.headerContentHeight
            + HexGridLayout.headerBottomPadding
            + HexGridLayout.dividerWidth
        return max(0, geometry.size.height - usedHeight)
    }

    static func sideContentWidth(bytesPerRow: Int) -> CGFloat {
        HexGridLayout.hexTextContentWidth(for: bytesPerRow)
    }

    static func pairedDataWidth(bytesPerRow: Int) -> CGFloat {
        sideContentWidth(bytesPerRow: bytesPerRow) * 2 + 1
    }
}
