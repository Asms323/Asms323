import MLX
import SwiftUI

@main
struct PocketAIApp: App {
    @State private var engine = LLMEngine()

    init() {
        // Keep MLX's GPU buffer cache small so iOS doesn't kill the app for memory use.
        MLX.Memory.cacheLimit = 20 * 1024 * 1024
    }

    var body: some Scene {
        WindowGroup {
            ChatView()
                .environment(engine)
        }
    }
}
