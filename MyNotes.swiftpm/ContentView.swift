import SwiftUI

struct ContentView: View {
    @State private var store = NoteStore()
    @State private var selection: Note.ID?
    @State private var searchText = ""

    private var visibleNotes: [Note] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return store.sortedNotes }
        return store.sortedNotes.filter { note in
            note.title.localizedCaseInsensitiveContains(query)
                || note.body.localizedCaseInsensitiveContains(query)
                || note.items.contains { $0.text.localizedCaseInsensitiveContains(query) }
        }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(visibleNotes) { note in
                    NoteRow(note: note)
                        .tag(note.id)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                delete(note.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                store.togglePin(note.id)
                            } label: {
                                Label(note.isPinned ? "Unpin" : "Pin",
                                      systemImage: note.isPinned ? "pin.slash" : "pin")
                            }
                            .tint(.orange)
                        }
                        .contextMenu {
                            Button {
                                store.togglePin(note.id)
                            } label: {
                                Label(note.isPinned ? "Unpin" : "Pin",
                                      systemImage: note.isPinned ? "pin.slash" : "pin")
                            }
                            Button(role: .destructive) {
                                delete(note.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .searchable(text: $searchText, prompt: "Search notes")
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        searchText = ""
                        selection = store.addNote()
                    } label: {
                        Label("New Note", systemImage: "square.and.pencil")
                    }
                    .keyboardShortcut("n", modifiers: .command)
                }
            }
            .overlay {
                if store.notes.isEmpty {
                    ContentUnavailableView(
                        "No Notes Yet",
                        systemImage: "note.text",
                        description: Text("Tap the pencil button to create your first note.")
                    )
                } else if visibleNotes.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        } detail: {
            if let id = selection,
               let index = store.notes.firstIndex(where: { $0.id == id }) {
                NoteEditor(note: $store.notes[index])
                    .id(id)
            } else {
                ContentUnavailableView(
                    "Select a Note",
                    systemImage: "note.text",
                    description: Text("Choose a note from the list, or create a new one.")
                )
            }
        }
        .onChange(of: store.notes) {
            store.save()
        }
    }

    private func delete(_ id: Note.ID) {
        if selection == id { selection = nil }
        store.delete(id)
    }
}

struct NoteRow: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                Text(note.displayTitle)
                    .font(.headline)
                    .lineLimit(1)
            }
            HStack(spacing: 8) {
                Text(note.updatedAt, format: .dateTime.month().day().hour().minute())
                if !note.items.isEmpty {
                    Label("\(note.doneCount)/\(note.items.count)", systemImage: "checklist")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            if !note.preview.isEmpty {
                Text(note.preview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}
