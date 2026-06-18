//
//  HexMacApp.swift
//  HexMac
//

import AppKit
import SwiftUI

@main
struct HexMacApp: App {
    @State private var viewModel = HexEditorViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
        Settings {
            SettingsView()
        }
        .commands {
            appMenuCommands
            fileMenuCommands
            editMenuCommands
            viewMenuCommands
            toolsMenuCommands
        }
    }

    @CommandsBuilder
    private var appMenuCommands: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button(String(localized: "About HexMac")) {
                NSApplication.shared.orderFrontStandardAboutPanel(
                    options: [NSApplication.AboutPanelOptionKey.credits: NSAttributedString()]
                )
            }
        }
    }

    @CommandsBuilder
    private var fileMenuCommands: some Commands {
        CommandGroup(replacing: .newItem) {}

        CommandGroup(after: .newItem) {
            Button(String(localized: "Open…")) {
                viewModel.openFilePanel()
            }
            .keyboardShortcut("o", modifiers: .command)

            Button(String(localized: "Close")) {
                viewModel.closeDocument()
            }
            .keyboardShortcut("w", modifiers: .command)
            .disabled(!viewModel.isDocumentOpen)
        }

        CommandGroup(replacing: .saveItem) {
            Button(String(localized: "Save")) {
                viewModel.save()
            }
            .keyboardShortcut("s", modifiers: .command)
            .disabled(!viewModel.canSave)

            Button(String(localized: "Save As…")) {
                viewModel.saveAs()
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
            .disabled(!viewModel.isDocumentOpen)
        }
    }

    @CommandsBuilder
    private var editMenuCommands: some Commands {
        CommandGroup(replacing: .undoRedo) {
            Button(String(localized: "Undo")) {
                viewModel.undo()
            }
            .keyboardShortcut("z", modifiers: .command)
            .disabled(!viewModel.isDocumentOpen)

            Button(String(localized: "Redo")) {
                viewModel.redo()
            }
            .keyboardShortcut("z", modifiers: [.command, .shift])
            .disabled(!viewModel.isDocumentOpen)
        }

        CommandGroup(replacing: .pasteboard) {
            Button(String(localized: "Copy")) {
                viewModel.copySelectionHex()
            }
            .keyboardShortcut("c", modifiers: .command)
            .disabled(!viewModel.hasSelection)

            Button(String(localized: "Clear…")) {
                viewModel.requestFillSelection()
            }
            .disabled(!viewModel.hasSelection)
        }
    }

    @CommandsBuilder
    private var viewMenuCommands: some Commands {
        CommandGroup(after: .toolbar) {
            Menu(String(localized: "Bytes per Row")) {
                ForEach(BytesPerRowSetting.allCases) { setting in
                    Button {
                        viewModel.setBytesPerRow(setting)
                    } label: {
                        if viewModel.bytesPerRow == setting {
                            Text("✓ \(setting.label)")
                        } else {
                            Text(setting.label)
                        }
                    }
                    .disabled(!viewModel.isDocumentOpen)
                }
            }
        }
    }

    @CommandsBuilder
    private var toolsMenuCommands: some Commands {
        CommandMenu(String(localized: "Tools")) {
            Button(String(localized: "Byte Histogram (Entire File)…")) {
                viewModel.openHistogramForAll()
            }
            .disabled(!viewModel.isDocumentOpen || viewModel.fileSize == 0)

            Button(String(localized: "Byte Histogram (Selection)…")) {
                viewModel.openHistogramForSelection()
            }
            .disabled(!viewModel.hasSelection)

            Divider()

            Button(String(localized: "Calculate CRC…")) {
                viewModel.openCRCSheet()
            }
            .disabled(!viewModel.hasSelection)
        }
    }
}
