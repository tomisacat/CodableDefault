import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(DemoScenario.grouped(), id: \.category) { group in
                    Section(group.category.rawValue) {
                        ForEach(group.scenarios) { scenario in
                            NavigationLink(value: scenario) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(scenario.title)
                                        .font(.headline)
                                    Text(scenario.summary)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            }
            .navigationTitle("CodableDefault")
            .navigationDestination(for: DemoScenario.self) { scenario in
                ScenarioDetailView(scenario: scenario)
            }
        }
    }
}

#Preview {
    ContentView()
}
