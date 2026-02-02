import Foundation

struct UserProfile: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var profileName: String // Display name (e.g. "Dev Info", "Manager")
    
    // Personal Details
    var fullName: String?
    var phone: String?
    var email: String?
    
    // Preferences
    var customInstructions: String?
    var preferredToneRawValue: String? // Optional preference
}

class ProfileService {
    private static let fileName = "CoverLetterGenerator_profiles.json"
    
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
    
    static func load() -> [UserProfile] {
        let alternateLegacyURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("profiles.json")
        
        // Migration logic: Move from Documents to Application Support if needed
        let legacyPaths = [legacyFileURL, alternateLegacyURL]
        
        for legacyPath in legacyPaths {
            if !FileManager.default.fileExists(atPath: fileURL.path) && FileManager.default.fileExists(atPath: legacyPath.path) {
                do {
                    try FileManager.default.moveItem(at: legacyPath, to: fileURL)
                    print("📦 Migrated profiles from Documents (\(legacyPath.lastPathComponent)) to Application Support")
                    break
                } catch {
                    print("❌ Failed to migrate profiles from \(legacyPath.lastPathComponent): \(error)")
                }
            }
        }
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let items = try JSONDecoder().decode([UserProfile].self, from: data)
            return items.sorted(by: { $0.profileName < $1.profileName })
        } catch {
            print("❌ Failed to load profiles: \(error)")
            return []
        }
    }
    
    static func save(_ items: [UserProfile]) {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: fileURL)
        } catch {
            print("❌ Failed to save profiles: \(error)")
        }
    }
}
