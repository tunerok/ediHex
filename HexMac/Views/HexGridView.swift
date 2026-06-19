//
//  HexGridView.swift
//  HexMac
//

import SwiftUI

struct HexGridView: View {
    let rowCount: Int
    let fileSize: Int
    let bytesPerRow: Int
    let dataRevision: Int
    let selection: HexSelection?
    let editingOffset: Int?
    let scrollTargetOffset: Int?
    let editingHexText: String
    let textEncoding: TextEncodingMode
    let isReadOnly: Bool
    let linkedScrollRow: Binding<Int?>?
    let onVisibleRowChanged: ((Int) -> Void)?
    let highlightColor: (Int) -> HighlightColor?
    let rowBytes: (Int) -> [UInt8]
    let onBeginSelection: (Int, Bool) -> Void
    let onUpdateSelection: (Int) -> Void
    let onEndSelection: (Int) -> Void
    let onHexDigit: (Character) -> Void
    let onBackspace: () -> Void
    let onCancelEdit: () -> Void
    let onAddHighlight: (HighlightColor) -> Void
    let onRemoveHighlight: (Int) -> Void
    let onCopySelection: () -> Void
    let onClearSelection: () -> Void
    let onCalculateCRC: () -> Void
    let onCalculateHash: () -> Void
    let onShowBinary: () -> Void
    let onSaveSelectionAsBinary: () -> Void
    let onSaveSelectionAsHex: () -> Void
    let onScrollTargetHandled: () -> Void

    @State private var isApplyingLinkedScroll = false

    init(
        rowCount: Int,
        fileSize: Int,
        bytesPerRow: Int,
        dataRevision: Int,
        selection: HexSelection?,
        editingOffset: Int?,
        scrollTargetOffset: Int?,
        editingHexText: String,
        textEncoding: TextEncodingMode,
        isReadOnly: Bool = false,
        linkedScrollRow: Binding<Int?>? = nil,
        onVisibleRowChanged: ((Int) -> Void)? = nil,
        highlightColor: @escaping (Int) -> HighlightColor?,
        rowBytes: @escaping (Int) -> [UInt8],
        onBeginSelection: @escaping (Int, Bool) -> Void,
        onUpdateSelection: @escaping (Int) -> Void,
        onEndSelection: @escaping (Int) -> Void,
        onHexDigit: @escaping (Character) -> Void,
        onBackspace: @escaping () -> Void,
        onCancelEdit: @escaping () -> Void,
        onAddHighlight: @escaping (HighlightColor) -> Void,
        onRemoveHighlight: @escaping (Int) -> Void,
        onCopySelection: @escaping () -> Void,
        onClearSelection: @escaping () -> Void,
        onCalculateCRC: @escaping () -> Void,
        onCalculateHash: @escaping () -> Void,
        onShowBinary: @escaping () -> Void,
        onSaveSelectionAsBinary: @escaping () -> Void,
        onSaveSelectionAsHex: @escaping () -> Void,
        onScrollTargetHandled: @escaping () -> Void
    ) {
        self.rowCount = rowCount
        self.fileSize = fileSize
        self.bytesPerRow = bytesPerRow
        self.dataRevision = dataRevision
        self.selection = selection
        self.editingOffset = editingOffset
        self.scrollTargetOffset = scrollTargetOffset
        self.editingHexText = editingHexText
        self.textEncoding = textEncoding
        self.isReadOnly = isReadOnly
        self.linkedScrollRow = linkedScrollRow
        self.onVisibleRowChanged = onVisibleRowChanged
        self.highlightColor = highlightColor
        self.rowBytes = rowBytes
        self.onBeginSelection = onBeginSelection
        self.onUpdateSelection = onUpdateSelection
        self.onEndSelection = onEndSelection
        self.onHexDigit = onHexDigit
        self.onBackspace = onBackspace
        self.onCancelEdit = onCancelEdit
        self.onAddHighlight = onAddHighlight
        self.onRemoveHighlight = onRemoveHighlight
        self.onCopySelection = onCopySelection
        self.onClearSelection = onClearSelection
        self.onCalculateCRC = onCalculateCRC
        self.onCalculateHash = onCalculateHash
        self.onShowBinary = onShowBinary
        self.onSaveSelectionAsBinary = onSaveSelectionAsBinary
        self.onSaveSelectionAsHex = onSaveSelectionAsHex
        self.onScrollTargetHandled = onScrollTargetHandled
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal) {
                VStack(alignment: .leading, spacing: 0) {
                    HexGridHeaderView(bytesPerRow: bytesPerRow)

                    Divider()

                    ScrollViewReader { proxy in
                        ScrollView(.vertical) {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(0..<rowCount, id: \.self) { rowIndex in
                                    HexRowView(
                                        rowIndex: rowIndex,
                                        bytes: rowBytes(rowIndex),
                                        fileSize: fileSize,
                                        bytesPerRow: bytesPerRow,
                                        selection: selection,
                                        editingOffset: editingOffset,
                                        editingHexText: editingHexText,
                                        textEncoding: textEncoding,
                                        highlightColor: highlightColor
                                    )
                                    .id(rowIndex)
                                }
                            }
                            .overlay {
                                HexSelectionHandlingView(
                                    rowCount: rowCount,
                                    fileSize: fileSize,
                                    bytesPerRow: bytesPerRow,
                                    editingOffset: editingOffset,
                                    selection: selection,
                                    isReadOnly: isReadOnly,
                                    onBeginSelection: onBeginSelection,
                                    onUpdateSelection: onUpdateSelection,
                                    onEndSelection: onEndSelection,
                                    onHexDigit: onHexDigit,
                                    onBackspace: onBackspace,
                                    onCancelEdit: onCancelEdit,
                                    onAddHighlight: onAddHighlight,
                                    onRemoveHighlight: onRemoveHighlight,
                                    onCopySelection: onCopySelection,
                                    onClearSelection: onClearSelection,
                                    onCalculateCRC: onCalculateCRC,
                                    onCalculateHash: onCalculateHash,
                                    onShowBinary: onShowBinary,
                                    onSaveSelectionAsBinary: onSaveSelectionAsBinary,
                                    onSaveSelectionAsHex: onSaveSelectionAsHex,
                                    highlightColor: highlightColor
                                )
                            }
                        }
                        .frame(height: verticalScrollHeight(in: geometry))
                        .onScrollGeometryChange(for: Int.self) { geometry in
                            let offsetY = geometry.contentOffset.y + geometry.contentInsets.top
                            guard rowCount > 0 else { return 0 }
                            let row = min(rowCount - 1, max(0, Int(offsetY / HexGridLayout.rowHeight)))
                            return row
                        } action: { _, row in
                            guard !isApplyingLinkedScroll else { return }
                            onVisibleRowChanged?(row)
                        }
                        .onChange(of: scrollTargetOffset) { _, target in
                            guard let target, bytesPerRow > 0 else { return }
                            let rowIndex = target / bytesPerRow
                            withAnimation {
                                proxy.scrollTo(rowIndex, anchor: .center)
                            }
                            onScrollTargetHandled()
                        }
                        .onChange(of: linkedScrollRow?.wrappedValue) { _, row in
                            guard let row else { return }
                            isApplyingLinkedScroll = true
                            proxy.scrollTo(row, anchor: .top)
                            DispatchQueue.main.async {
                                isApplyingLinkedScroll = false
                            }
                        }
                    }
                }
                .padding(HexGridLayout.contentPadding)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func verticalScrollHeight(in geometry: GeometryProxy) -> CGFloat {
        let usedHeight = HexGridLayout.headerContentHeight
            + HexGridLayout.headerBottomPadding
            + HexGridLayout.dividerWidth
            + HexGridLayout.contentPadding * 2
        return max(0, geometry.size.height - usedHeight)
    }
}
