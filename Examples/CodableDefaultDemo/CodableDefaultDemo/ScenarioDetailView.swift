import SwiftUI

struct ScenarioDetailView: View {
    let scenario: DemoScenario

    @State private var outcome: DemoOutcome?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GroupBox("About") {
                    Text(scenario.summary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Highlights") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(scenario.highlights, id: \.self) { highlight in
                            Label(highlight, systemImage: "checkmark.circle.fill")
                                .labelStyle(.titleAndIcon)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Sample JSON") {
                    Text(scenario.json.trimmingCharacters(in: .whitespacesAndNewlines))
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }

                GroupBox("Result") {
                    if let outcome {
                        switch outcome {
                        case let .success(message):
                            Label("Decode succeeded", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                                .font(.headline)
                            Text(message)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        case let .failure(message):
                            Label("Decode failed", systemImage: "xmark.octagon.fill")
                                .foregroundStyle(.orange)
                                .font(.headline)
                            Text(message)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                    } else {
                        ProgressView("Running demo…")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(scenario.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Run Again") {
                    runDemo()
                }
            }
        }
        .onAppear {
            if outcome == nil {
                runDemo()
            }
        }
    }

    private func runDemo() {
        outcome = DemoRunner.run(scenario)
    }
}

#Preview {
    NavigationStack {
        ScenarioDetailView(scenario: DemoScenario.all[0])
    }
}
