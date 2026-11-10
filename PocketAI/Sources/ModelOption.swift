import Foundation

/// Small, 4-bit quantized models from the mlx-community Hugging Face org that fit on an iPhone.
/// Downloaded once on first use, then cached on the device and run fully offline.
struct ModelOption: Identifiable, Hashable {
    let id: String          // Hugging Face repo id
    let name: String
    let approxSize: String
    let note: String

    static let all: [ModelOption] = [
        ModelOption(id: "mlx-community/Qwen3-0.6B-4bit",
                    name: "Qwen3 0.6B", approxSize: "~350 MB",
                    note: "Fastest. Works on any recent iPhone."),
        ModelOption(id: "mlx-community/Llama-3.2-1B-Instruct-4bit",
                    name: "Llama 3.2 1B", approxSize: "~700 MB",
                    note: "Good balance of speed and quality."),
        ModelOption(id: "mlx-community/gemma-3-1b-it-qat-4bit",
                    name: "Gemma 3 1B", approxSize: "~750 MB",
                    note: "Strong small chat model."),
        ModelOption(id: "mlx-community/Qwen3-1.7B-4bit",
                    name: "Qwen3 1.7B", approxSize: "~1 GB",
                    note: "Smarter. Best on iPhone 15 Pro or newer."),
        ModelOption(id: "mlx-community/Llama-3.2-3B-Instruct-4bit",
                    name: "Llama 3.2 3B", approxSize: "~1.8 GB",
                    note: "Highest quality. Needs 8 GB RAM (iPhone 15 Pro+)."),
    ]

    static let `default` = all[0]
}
