//
//  EditorTabBarView.swift
//  HexMac
//

import SwiftUI

struct EditorTabBarView: View {
    @Bindable var workspace: WorkspaceViewModel
    let group: EditorTabGroup

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(group.panes) { pane in
                    tabItem(for: pane)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(.bar)
        .dropDestination(for: String.self) { items, _ in
            guard let idString = items.first,
                  let paneID = UUID(uuidString: idString) else {
                return false
            }
            workspace.movePane(paneID, toGroupID: group.id)
            return true
        }
    }

    private func tabItem(for pane: DocumentPaneViewModel) -> some View {
        let isActive = workspace.activePaneID == pane.id

        return HStack(spacing: 6) {
            Text(pane.displayTitle)
                .lineLimit(1)
                .font(.callout)

            Button {
                workspace.requestClosePane(id: pane.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(isActive ? 1 : 0.6)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isActive ? Color.accentColor.opacity(0.15) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            workspace.activatePane(id: pane.id)
        }
        .draggable(pane.id.uuidString)
    }
}
