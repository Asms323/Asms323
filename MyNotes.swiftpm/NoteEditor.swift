import SwiftUI

struct NoteEditor: View {
    @Binding var note: Note
    @State private var newItemText = ""
    @FocusState private var newItemFocused: Bool

    var body: some View {
        List {
            Section {
                TextField("Title", text: $note.title, axis: .vertical)
                    .font(.largeTitle.bold())
            }

            Section("Checklist") {
                ForEach($note.items) { $item in
                    HStack(spacing: 12) {
                        Button {
                            withAnimation { item.isDone.toggle() }
                        } label: {
                            Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundStyle(item.isDone ? Color.green : Color.secondary)
                        }
                        .buttonStyle(.plain)

                        TextField("Item", text: $item.text, axis: .vertical)
                            .strikethrough(item.isDone)
                            .foregroundStyle(item.isDone ? .secondary : .primary)
                    }
                }
                .onDelete { note.items.remove(atOffsets: $0) }
                .onMove { note.items.move(fromOffsets: $0, toOffset: $1) }

                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.tint)
                    TextField("Add an item", text: $newItemText)
                        .focused($newItemFocused)
                        .submitLabel(.next)
                        .onSubmit(addItem)
                }
            }

            Section("Notes") {
                TextEditor(text: $note.body)
                    .frame(minHeight: 280)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    note.isPinned.toggle()
                } label: {
                    Label(note.isPinned ? "Unpin" : "Pin",
                          systemImage: note.isPinned ? "pin.fill" : "pin")
                }
                ShareLink(item: note.shareText)
                EditButton()
            }
        }
        .onChange(of: note.title) { touch() }
        .onChange(of: note.body) { touch() }
        .onChange(of: note.items) { touch() }
    }

    private func addItem() {
        let text = newItemText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        note.items.append(ChecklistItem(text: text))
        newItemText = ""
        newItemFocused = true
    }

    private func touch() {
        note.updatedAt = .now
    }
}
