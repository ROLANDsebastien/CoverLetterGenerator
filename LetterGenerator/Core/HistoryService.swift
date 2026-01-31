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
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportURL = paths[0].appendingPathComponent("CoverLetterGenerator", isDirectory: true)
        
        // Ensure directory exists
        if !FileManager.default.fileExists(atPath: appSupportURL.path) {
            try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        }
        
        return appSupportURL.appendingPathComponent(fileName)
    }
    
    private static var legacyFileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(fileName)
    }
    
    static func load() -> [HistoryItem] {
        let alternateLegacyURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("history.json")
        
        // Migration logic: Move from Documents to Application Support if needed
        let legacyPaths = [legacyFileURL, alternateLegacyURL]
        
        for legacyPath in legacyPaths {
            if !FileManager.default.fileExists(atPath: fileURL.path) && FileManager.default.fileExists(atPath: legacyPath.path) {
                do {
                    try FileManager.default.moveItem(at: legacyPath, to: fileURL)
                    print("📦 Migrated history from Documents (\(legacyPath.lastPathComponent)) to Application Support")
                    break // Migrated one, that's enough
                } catch {
                    print("❌ Failed to migrate history from \(legacyPath.lastPathComponent): \(error)")
                }
            }
        }
        
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
