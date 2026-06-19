//
//  TerminalPanelView.swift
//  HexMac
//

import SwiftUI

struct TerminalPanelView: View {
    var pane: DocumentPaneViewModel?

    var body: some View {
        if let pane {
            TerminalPanelBoundView(pane: pane)
        } else {
            TerminalPanelEmptyView()
        }
    }
}

private struct TerminalPanelBoundView: View {
    @Bindable var pane: DocumentPaneViewModel
    @State private var commandInput = ""

    var body: some View {
        TerminalPanelContent(
            history: pane.terminalHistory,
            commandInput: $commandInput,
            isEnabled: true,
            onSubmit: {
                let command = commandInput
                commandInput = ""
                guard !command.isEmpty else { return }
                pane.executeTerminalCommand(command)
            }
        )
    }
}

private struct TerminalPanelEmptyView: View {
    @State private var commandInput = ""

    var body: some View {
        TerminalPanelContent(
            history: [],
            commandInput: $commandInput,
            isEnabled: false,
            onSubmit: {}
        )
    }
}

private struct TerminalPanelContent: View {
    let history: [TerminalLine]
    @Binding var commandInput: String
    let isEnabled: Bool
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(String(localized: "Terminal"))
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(history) { line in
                            terminalLineView(line)
                                .id(line.id)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: .infinity)
                .scrollIndicators(.visible)
                .onChange(of: history.count) { _, _ in
                    if let last = history.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            HStack(spacing: 8) {
                Text("›")
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)

                TextField(String(localized: "Enter command"), text: $commandInput)
                    .font(.callout.monospaced())
                    .textFieldStyle(.plain)
                    .disabled(!isEnabled)
                    .onSubmit(onSubmit)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.background.secondary)
    }

    @ViewBuilder
    private func terminalLineView(_ line: TerminalLine) -> some View {
        switch line.kind {
        case .input:
            Text("› \(line.text)")
                .font(.caption.monospaced())
                .foregroundStyle(.primary)
        case .output:
            Text(line.text)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        case .error:
            Text(line.text)
                .font(.caption.monospaced())
                .foregroundStyle(.red)
                .textSelection(.enabled)
        }
    }
}

#Preview {
    TerminalPanelView(pane: DocumentPaneViewModel())
        .frame(width: 520, height: 92)
}
