import Foundation
import HuggingFace
import MLX
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Observation
import Tokenizers

struct ChatMessage: Identifiable, Equatable {
    enum Role { case user, assistant }
    let id = UUID()
    let role: Role
    var text: String
}

/// Downloads a model from Hugging Face (first run only), loads it with MLX and runs it on the iPhone GPU.
@MainActor
@Observable
final class LLMEngine {
    enum State: Equatable {
        case idle
        case downloading(Double)
        case ready
        case failed(String)
    }

    var state: State = .idle
    var messages: [ChatMessage] = []
    var isGenerating = false
    var tokensPerSecond: Double = 0
    var selectedModel: ModelOption = .default
    var systemPrompt = "You are a helpful, concise assistant running privately on the user's iPhone."

    private var container: ModelContainer?
    private var session: ChatSession?
    private var loadedModelID: String?
    private var generationTask: Task<Void, Never>?

    private var parameters: GenerateParameters {
        GenerateParameters(maxTokens: 1024, temperature: 0.6, topP: 0.9)
    }

    func loadSelectedModel() async {
        if loadedModelID == selectedModel.id, container != nil { return }
        stop()
        container = nil
        session = nil
        state = .downloading(0)
        do {
            let config = ModelConfiguration(id: selectedModel.id)
            let container = try await LLMModelFactory.shared.loadContainer(
                from: #hubDownloader(),
                using: #huggingFaceTokenizerLoader(),
                configuration: config,
                progressHandler: { progress in
                    let fraction = progress.fractionCompleted
                    Task { @MainActor in self.state = .downloading(fraction) }
                }
            )
            self.container = container
            self.loadedModelID = selectedModel.id
            resetConversation()
            state = .ready
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func resetConversation() {
        stop()
        messages.removeAll()
        if let container {
            session = ChatSession(container, instructions: systemPrompt, generateParameters: parameters)
        }
    }

    func send(_ prompt: String) {
        let prompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, let session, !isGenerating else { return }

        messages.append(ChatMessage(role: .user, text: prompt))
        messages.append(ChatMessage(role: .assistant, text: ""))
        let index = messages.count - 1
        isGenerating = true
        tokensPerSecond = 0

        generationTask = Task {
            let start = Date()
            var chunks = 0
            do {
                for try await chunk in session.streamResponse(to: prompt) {
                    if Task.isCancelled { break }
                    messages[index].text += chunk
                    chunks += 1
                    let elapsed = Date().timeIntervalSince(start)
                    if elapsed > 0 { tokensPerSecond = Double(chunks) / elapsed }
                }
            } catch {
                messages[index].text += "\n\n⚠️ \(error.localizedDescription)"
            }
            messages[index].text = Self.stripThinking(messages[index].text)
            isGenerating = false
            Memory.clearCache()
        }
    }

    func stop() {
        generationTask?.cancel()
        generationTask = nil
        isGenerating = false
    }

    /// Qwen3 emits <think>…</think> reasoning blocks; hide them from the final answer.
    static func stripThinking(_ text: String) -> String {
        guard let end = text.range(of: "</think>") else { return text }
        return String(text[end.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
