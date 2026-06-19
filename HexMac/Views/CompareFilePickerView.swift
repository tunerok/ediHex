//
//  CompareFilePickerView.swift
//  HexMac
//

import SwiftUI

struct CompareFilePickerView: View {
    @Bindable var workspace: WorkspaceViewModel
    let panes: [DocumentPaneViewModel]
    let presetLeftPaneID: UUID?

    @State private var leftPaneID: UUID?
    @State private var rightPaneID: UUID?

    private var canCompare: Bool {
        guard let leftPaneID, let rightPaneID else { return false }
        return leftPaneID != rightPaneID
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "Compare Files"))
                .font(.title2.weight(.semibold))

            Picker(String(localized: "Left file"), selection: $leftPaneID) {
                Text(String(localized: "Select a file")).tag(Optional<UUID>.none)
                ForEach(panes) { pane in
                    Text(pane.displayTitle).tag(Optional(pane.id))
                }
            }

            Picker(String(localized: "Right file"), selection: $rightPaneID) {
                Text(String(localized: "Select a file")).tag(Optional<UUID>.none)
                ForEach(panes) { pane in
                    Text(pane.displayTitle).tag(Optional(pane.id))
                }
            }

            if let leftPaneID, let rightPaneID, leftPaneID == rightPaneID {
                Text(String(localized: "Choose two different files."))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()
                Button(String(localized: "Cancel"), role: .cancel) {
                    workspace.cancelComparePicker()
                }
                Button(String(localized: "Compare")) {
                    guard let leftPaneID, let rightPaneID else { return }
                    workspace.confirmCompare(leftPaneID: leftPaneID, rightPaneID: rightPaneID)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canCompare)
            }
        }
        .padding(20)
        .frame(width: 420)
        .onAppear {
            leftPaneID = presetLeftPaneID ?? panes.first?.id
            if let presetLeftPaneID {
                rightPaneID = panes.first { $0.id != presetLeftPaneID }?.id
            } else {
                rightPaneID = panes.dropFirst().first?.id
            }
        }
    }
}
