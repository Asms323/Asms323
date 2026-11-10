import SwiftUI

struct ChatView: View {
    @Environment(LLMEngine.self) private var engine
    @State private var input = ""
    @State private var showSettings = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                content
                if engine.state == .ready { inputBar }
            }
            .navigationTitle("Pocket AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { engine.resetConversation() } label: { Image(systemName: "square.and.pencil") }
                        .disabled(engine.state != .ready)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
    }

    @ViewBuilder private var content: some View {
        switch engine.state {
        case .idle:
            StartView()
        case .downloading(let fraction):
            VStack(spacing: 16) {
                ProgressView(value: fraction)
                    .padding(.horizontal, 40)
                Text(fraction < 1 ? "Downloading \(engine.selectedModel.name)… \(Int(fraction * 100))%"
                                  : "Loading model into memory…")
                    .foregroundStyle(.secondary)
                Text("Only needed once. After this it works offline.")
                    .font(.footnote).foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            ContentUnavailableView {
                Label("Couldn't load model", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try again") { Task { await engine.loadSelectedModel() } }
                    .buttonStyle(.borderedProminent)
            }
        case .ready:
            messageList
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if engine.messages.isEmpty {
                        Text("Running \(engine.selectedModel.name) on your iPhone. Nothing leaves your device.")
                            .font(.footnote).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity).padding(.top, 40)
                    }
                    ForEach(engine.messages) { MessageBubble(message: $0).id($0.id) }
                    if engine.isGenerating, engine.tokensPerSecond > 0 {
                        Text(String(format: "%.1f tokens/s", engine.tokensPerSecond))
                            .font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: engine.messages.last?.text) {
                if let last = engine.messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
            }
        }
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Message", text: $input, axis: .vertical)
                .lineLimit(1...5)
                .focused($inputFocused)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
            if engine.isGenerating {
                Button { engine.stop() } label: {
                    Image(systemName: "stop.circle.fill").font(.system(size: 32))
                }
            } else {
                Button {
                    engine.send(input)
                    input = ""
                } label: {
                    Image(systemName: "arrow.up.circle.fill").font(.system(size: 32))
                }
                .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.horizontal).padding(.vertical, 8)
        .background(.bar)
    }
}

private struct StartView: View {
    @Environment(LLMEngine.self) private var engine

    var body: some View {
        @Bindable var engine = engine
        Form {
            Section {
                Picker("Model", selection: $engine.selectedModel) {
                    ForEach(ModelOption.all) { model in
                        VStack(alignment: .leading) {
                            Text("\(model.name)  ·  \(model.approxSize)")
                            Text(model.note).font(.caption).foregroundStyle(.secondary)
                        }
                        .tag(model)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } header: {
                Text("Choose an on-device model")
            } footer: {
                Text("The model downloads once from Hugging Face, then runs entirely on your iPhone's GPU — private and offline.")
            }
            Section {
                Button("Download & Start") { Task { await engine.loadSelectedModel() } }
                    .frame(maxWidth: .infinity)
                    .fontWeight(.semibold)
            }
        }
    }
}

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            Text(message.text.isEmpty ? "…" : displayText)
                .textSelection(.enabled)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .foregroundStyle(message.role == .user ? Color.white : Color.primary)
                .background(message.role == .user ? Color.accentColor : Color(.secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 18))
            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }

    private var displayText: AttributedString {
        let text = message.text.hasPrefix("<think>") && !message.text.contains("</think>")
            ? "Thinking…" : LLMEngine.stripThinking(message.text)
        return (try? AttributedString(markdown: text,
                                      options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
            ?? AttributedString(text)
    }
}

private struct SettingsView: View {
    @Environment(LLMEngine.self) private var engine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var engine = engine
        NavigationStack {
            Form {
                Section("Model") {
                    Picker("Model", selection: $engine.selectedModel) {
                        ForEach(ModelOption.all) { Text("\($0.name) (\($0.approxSize))").tag($0) }
                    }
                    Button("Load selected model") {
                        dismiss()
                        Task { await engine.loadSelectedModel() }
                    }
                }
                Section {
                    TextField("System prompt", text: $engine.systemPrompt, axis: .vertical)
                        .lineLimit(3...8)
                } header: {
                    Text("System prompt")
                } footer: {
                    Text("Applies when you start a new chat.")
                }
            }
            .navigationTitle("Settings")
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}
