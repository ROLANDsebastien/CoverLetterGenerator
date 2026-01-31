import Foundation

struct HistoryItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date
    var jobDescription: String
    var generatedLetter: String
    var toneRawValue: String
    
    // Helper to extract a title from the JD
    var title: String {
        let lines = jobDescription.components(separatedBy: .newlines)
        // Try to take the first non-empty line
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return String(trimmed.prefix(50)) // Cap at 50 chars
            }
        }
        return "Untitled Application"
    }
}

class HistoryService {
    private static let fileName = "CoverLetterGenerator_history.json"
    
    private static var fileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(fileName)
    }
    
    static func load() -> [HistoryItem] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let items = try JSONDecoder().decode([HistoryItem].self, from: data)
            return items.sorted(by: { $0.date > $1.date })
        } catch {
            print("❌ Failed to load history: \(error)")
            return []
        }
    }
    
    static func save(_ items: [HistoryItem]) {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: fileURL)
        } catch {
            print("❌ Failed to save history: \(error)")
        }
    }
}
