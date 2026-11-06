import Foundation
import Observation

/// Keeps all notes in memory and saves them to a JSON file in the app's Documents folder.
@MainActor
@Observable
final class NoteStore {
    var notes: [Note] = []

    private let fileURL = URL.documentsDirectory.appending(path: "notes.json")

    init() {
        load()
    }

    /// Pinned notes first, then most recently edited.
    var sortedNotes: [Note] {
        notes.sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned }
            return $0.updatedAt > $1.updatedAt
        }
    }

    @discardableResult
    func addNote() -> Note.ID {
        let note = Note()
        notes.append(note)
        return note.id
    }

    func delete(_ id: Note.ID) {
        notes.removeAll { $0.id == id }
    }

    func togglePin(_ id: Note.ID) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[index].isPinned.toggle()
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(notes)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save notes: \(error)")
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Note].self, from: data)
        else { return }
        notes = decoded
    }
}
