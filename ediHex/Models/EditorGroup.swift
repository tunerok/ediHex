//
//  EditorGroup.swift
//  ediHex
//

import Foundation

enum SplitAxis: Equatable {
    case horizontal
    case vertical
}

struct EditorTabGroup: Identifiable {
    let id: UUID
    var panes: [DocumentPaneViewModel]
    var activePaneID: UUID?

    init(id: UUID = UUID(), panes: [DocumentPaneViewModel] = [], activePaneID: UUID? = nil) {
        self.id = id
        self.panes = panes
        self.activePaneID = activePaneID
    }

    var activePane: DocumentPaneViewModel? {
        guard let activePaneID else { return panes.first }
        return panes.first { $0.id == activePaneID } ?? panes.first
    }
}

indirect enum EditorGroupNode: Identifiable {
    case leaf(EditorTabGroup)
    case split(id: UUID, axis: SplitAxis, ratio: CGFloat, first: EditorGroupNode, second: EditorGroupNode)

    var id: UUID {
        switch self {
        case .leaf(let group):
            return group.id
        case .split(let id, _, _, _, _):
            return id
        }
    }
}
