import Foundation

class AIService {
    
    enum AIModel: String, CaseIterable {
        // Gemini Models (gemini-cli)
        case gemini3Pro = "gemini-3-pro"
        case gemini3Flash = "gemini-3-flash"
        
        // OpenCode Models (opencode-cli)
        case bigPickle = "opencode/big-pickle"
        case glm47 = "opencode/glm-4.7-free"
        case grokCodeFast1 = "opencode/grok-code"
        case minimaxM21 = "opencode/minimax-m2.1-free"
        
        // Mistral Models (mistral-vibe cli)
        case mistralVibe = "mistral-vibe"
        
        var displayName: String {
            switch self {
            case .gemini3Pro: return "Gemini 3 Pro"
            case .gemini3Flash: return "Gemini 3 Flash"
            case .bigPickle: return "Big Pickle"
            case .glm47: return "GLM-4.7"
            case .grokCodeFast1: return "Grok Code Fast 1"
            case .minimaxM21: return "MiniMax M2.1"
            case .mistralVibe: return "Mistral Vibe"
            }
        }
        
        var provider: String {
            switch self {
            case .gemini3Pro, .gemini3Flash: return "gemini"
            case .bigPickle, .glm47, .grokCodeFast1, .minimaxM21: return "opencode"
            case .mistralVibe: return "mistral"
            }
        }
        
        var executablePath: String {
            let fileManager = FileManager.default
            let binaryName: String
            switch provider {
            case "gemini": binaryName = "gemini"
            case "opencode": binaryName = "opencode"
            case "mistral": binaryName = "mistral-vibe"
            default: return "/usr/bin/false"
            }
            
            let candidatePaths = [
                "/opt/homebrew/bin/\(binaryName)",
                "/usr/local/bin/\(binaryName)",
                "/usr/bin/\(binaryName)"
            ]
            
            for path in candidatePaths {
                if fileManager.fileExists(atPath: path) {
                    return path
                }
            }
            return "/opt/homebrew/bin/\(binaryName)" // Fallback to default
        }
        
        var arguments: [String] {
            switch provider {
            case "gemini": return ["-m", self.rawValue, "--yolo"]
            case "opencode": return ["run", "--model", self.rawValue]
            case "mistral": return ["run", "--model", "mistral-vibe"] // Assuming specific run command
            default: return []
            }
        }
        
        var usesStdin: Bool {
            return provider == "opencode" || provider == "mistral"
        }
    }

    static func generateCoverLetter(
        jobDescription: String, 
        cvContext: String, 
        instructions: String,
        model: AIModel,
        completion: @escaping (String?) -> Void
    ) {
        let prompt = """
            Generate a professional cover letter based on the following CV context and job description.
            
            CV CONTEXT:
            \(cvContext)
            
            JOB POSTING:
            \(jobDescription)
            
            INSTRUCTIONS:
            \(instructions.isEmpty ? "None" : instructions)
            
            REQUIREMENTS:
            - Professional tone.
            - Write ONLY the cover letter text starting with salutation.
            - Do not include headers like [Date].
            - Write in the same language as the job posting.
            """

        Task {
            do {
                let input = model.usesStdin ? prompt : nil
                let args = model.usesStdin ? model.arguments : model.arguments + [prompt]
                
                let output = try await AIProcessService.runCommand(
                    executablePath: model.executablePath,
                    arguments: args,
                    input: input,
                    timeout: 120.0
                )
                
                await MainActor.run { completion(output) }
            } catch {
                print("❌ AI Error: \(error.localizedDescription)")
                await MainActor.run { completion(nil) }
            }
        }
    }
}
