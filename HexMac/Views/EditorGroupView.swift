//
//  EditorGroupView.swift
//  HexMac
//

import SwiftUI

struct EditorGroupView: View {
    @Bindable var workspace: WorkspaceViewModel
    let node: EditorGroupNode

    var body: some View {
        switch node {
        case .leaf(let group):
            leafView(group: group)
        case .split(_, let axis, _, let first, let second):
            splitView(axis: axis, first: first, second: second)
        }
    }

    @ViewBuilder
    private func leafView(group: EditorTabGroup) -> some View {
        let currentGroup = workspace.findTabGroup(id: group.id) ?? group
        let isFocused = workspace.activeGroupID == group.id

        VStack(spacing: 0) {
            EditorTabBarView(workspace: workspace, group: currentGroup)

            Divider()

            ZStack {
                ForEach(currentGroup.panes) { pane in
                    let isActive = pane.id == currentGroup.activePaneID
                    DocumentPaneView(workspace: workspace, pane: pane)
                        .id(pane.id)
                        .opacity(isActive ? 1 : 0)
                        .allowsHitTesting(isActive)
                        .accessibilityHidden(!isActive)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay {
            if isFocused {
                RoundedRectangle(cornerRadius: 2)
                    .strokeBorder(Color.accentColor.opacity(0.5), lineWidth: 1)
            }
        }
        .onTapGesture {
            workspace.activateGroup(id: group.id)
        }
    }

    @ViewBuilder
    private func splitView(axis: SplitAxis, first: EditorGroupNode, second: EditorGroupNode) -> some View {
        switch axis {
        case .horizontal:
            HSplitView {
                EditorGroupView(workspace: workspace, node: first)
                    .layoutPriority(1)
                EditorGroupView(workspace: workspace, node: second)
                    .layoutPriority(1)
            }
        case .vertical:
            VSplitView {
                EditorGroupView(workspace: workspace, node: first)
                    .layoutPriority(1)
                EditorGroupView(workspace: workspace, node: second)
                    .layoutPriority(1)
            }
        }
    }
}
