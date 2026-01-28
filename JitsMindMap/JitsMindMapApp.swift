import SwiftUI
import SwiftData

@main
struct JitsMindMapApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Technique.self)
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TreeView(modelContext: modelContext)
    }
}
