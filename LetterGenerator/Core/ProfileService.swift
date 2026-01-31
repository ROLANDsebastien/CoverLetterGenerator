import Foundation

struct UserProfile: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var profileName: String // Display name (e.g. "Dev Info", "Manager")
    
    // Personal Details
    var fullName: String
    var phone: String
    var email: String
    
    // Preferences
    var customInstructions: String
    var preferredToneRawValue: String? // Optional preference
}

class ProfileService {
    private static let fileName = "CoverLetterGenerator_profiles.json"
    
    private static var fileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(fileName)
    }
    
    static func load() -> [UserProfile] {
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
