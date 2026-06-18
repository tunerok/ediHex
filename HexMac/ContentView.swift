//
//  ContentView.swift
//  HexMac
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Bindable var viewModel: HexEditorViewModel
    @AppStorage("textEncoding") private var storedEncoding = TextEncodingMode.ascii.rawValue

    var body: some View {
        Group {
            if viewModel.isDocumentOpen {
                HexEditorView(viewModel: viewModel)
            } else {
                EmptyStateView(onOpen: viewModel.openFilePanel)
            }
        }
        .frame(minWidth: 720, minHeight: 480)
        .navigationTitle(viewModel.windowTitle)
        .toolbarRole(.editor)
        .onAppear {
            syncEncodingFromStorage()
        }
        .onChange(of: storedEncoding) { _, _ in
            syncEncodingFromStorage()
        }
        .onChange(of: viewModel.textEncoding) { _, newValue in
            storedEncoding = newValue.rawValue
        }
        .onDrop(of: [.fileURL], isTargeted: nil, perform: handleDrop)
        .alert(
            String(localized: "Error"),
            isPresented: Binding(
                get: { viewModel.showError },
                set: { viewModel.showError = $0 }
            )
        ) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func syncEncodingFromStorage() {
        let mode = TextEncodingMode(rawValue: storedEncoding) ?? .ascii
        if viewModel.textEncoding != mode {
            viewModel.textEncoding = mode
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }
            Task { @MainActor in
                viewModel.openFile(from: url)
            }
        }
        return true
    }
}

#Preview {
    ContentView(viewModel: HexEditorViewModel())
}
