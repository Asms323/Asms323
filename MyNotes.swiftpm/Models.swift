import Foundation

struct ChecklistItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var text: String
    var isDone = false
}

struct Note: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String = ""
    var body: String = ""
    var items: [ChecklistItem] = []
    var isPinned = false
    var updatedAt = Date()

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled" : trimmed
    }

    var preview: String {
        body.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
    }

    var doneCount: Int { items.filter(\.isDone).count }

    /// Plain-text version used by the Share button.
    var shareText: String {
        var lines = [displayTitle, ""]
        for item in items {
            lines.append("\(item.isDone ? "☑︎" : "☐") \(item.text)")
        }
        if !items.isEmpty { lines.append("") }
        lines.append(body)
        return lines.joined(separator: "\n")
    }
}
