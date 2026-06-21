//
//  InspectorFindResultsSection.swift
//  ediHex
//

import SwiftUI

struct InspectorFindResultsSection: View {
    let session: FindSession
    let canFindPrevious: Bool
    let canFindNext: Bool
    let onFindPrevious: () -> Void
    let onFindNext: () -> Void
    let onClearFind: () -> Void

    var body: some View {
        Section(String(localized: "Find Results")) {
            LabeledContent(String(localized: "Query")) {
                Text(session.queryText)
                    .font(.callout.monospaced())
                    .textSelection(.enabled)
            }

            LabeledContent(String(localized: "Parameters")) {
                Text(session.parametersDescription)
                    .font(.callout)
            }

            LabeledContent(String(localized: "Results")) {
                Text(session.resultsSummary)
                    .font(.callout)
            }

            if session.hasMatches {
                LabeledContent(String(localized: "Current")) {
                    Text(
                        String(
                            localized: "Match \(session.currentIndex + 1) of \(session.matches.count)",
                            comment: "Find navigation status in Inspector"
                        )
                    )
                    .font(.callout.monospaced())
                }
            }

            HStack {
                Button(String(localized: "Previous"), action: onFindPrevious)
                    .disabled(!canFindPrevious)

                Button(String(localized: "Next"), action: onFindNext)
                    .disabled(!canFindNext)

                Spacer()

                Button(String(localized: "Clear"), role: .destructive, action: onClearFind)
            }
        }
    }
}

#if DEBUG
#Preview {
    Form {
        InspectorFindResultsSection(
            session: FindSession(
                queryText: "DE AD BE",
                pattern: [0xDE, 0xAD, 0xBE],
                mode: .hex,
                entireFile: true,
                direction: .down,
                matches: [16, 48, 128],
                currentIndex: 1,
                isScanningComplete: true
            ),
            canFindPrevious: true,
            canFindNext: true,
            onFindPrevious: {},
            onFindNext: {},
            onClearFind: {}
        )
    }
    .formStyle(.grouped)
}
#endif
