import Foundation

class AIService {
    
    struct AIModelInfo: Identifiable, Hashable {
        let id: String
        let modelName: String // The name used in CLI (e.g. "gemini-1.5-pro")
        let displayName: String // User friendly name
        let provider: String // "gemini", "opencode", "mistral"
        let executablePath: String
        
        static func == (lhs: AIModelInfo, rhs: AIModelInfo) -> Bool {
            return lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
    
    // Default fallback models if discovery fails entirely
    private static let defaultModels = [
        AIModelInfo(id: "gemini-3-flash-default", modelName: "gemini-3-flash", displayName: "Gemini 3 Flash (Default)", provider: "gemini", executablePath: "/opt/homebrew/bin/gemini"),
        AIModelInfo(id: "opencode-default", modelName: "opencode/big-pickle", displayName: "Big Pickle (Default)", provider: "opencode", executablePath: "/opt/homebrew/bin/opencode")
    ]
    
    static func fetchAvailableModels() async -> [AIModelInfo] {
        var models: [AIModelInfo] = []
        
        // 1. Gemini Models
        // The gemini CLI does not have a machine-readable 'list' command, so we provide the valid models found in its source headers.
        if let geminiPath = findBinary(name: "gemini") {
             models.append(AIModelInfo(id: "gemini-2.5-flash", modelName: "gemini-2.5-flash", displayName: "Gemini 2.5 Flash", provider: "gemini", executablePath: geminiPath))
             models.append(AIModelInfo(id: "gemini-2.5-pro", modelName: "gemini-2.5-pro", displayName: "Gemini 2.5 Pro", provider: "gemini", executablePath: geminiPath))
             models.append(AIModelInfo(id: "gemini-3-flash-preview", modelName: "gemini-3-flash-preview", displayName: "Gemini 3 Flash (Preview)", provider: "gemini", executablePath: geminiPath))
             models.append(AIModelInfo(id: "gemini-3-pro-preview", modelName: "gemini-3-pro-preview", displayName: "Gemini 3 Pro (Preview)", provider: "gemini", executablePath: geminiPath))
        }
        
        // 2. Discover OpenCode Models
        // Command: opencode models
        if let opencodePath = findBinary(name: "opencode") {
            let found = await discoverModels(binaryPath: opencodePath, listCommand: ["models"], provider: "opencode")
            if found.isEmpty {
                 models.append(AIModelInfo(id: "opencode-big-pickle", modelName: "opencode/big-pickle", displayName: "Big Pickle", provider: "opencode", executablePath: opencodePath))
            } else {
                models.append(contentsOf: found)
            }
        }
        
        // 3. Discover Mistral Models
        // Command: mistral model list (Assuming 'mistral-vibe' is the binary name based on previous code, but user said 'mistral cli')
        // We will try 'mistral' first, then 'mistral-vibe'
        if let mistralPath = findBinary(name: "mistral") ?? findBinary(name: "mistral-vibe") {
             // For Mistral, we might need to parse specific output.
             // Assuming simple line based output for now or adding static
             models.append(AIModelInfo(id: "mistral-large", modelName: "mistral-large-latest", displayName: "Mistral Large", provider: "mistral", executablePath: mistralPath))
             models.append(AIModelInfo(id: "mistral-medium", modelName: "mistral-medium-latest", displayName: "Mistral Medium", provider: "mistral", executablePath: mistralPath))
        }
        
        return models.isEmpty ? defaultModels : models
    }
    
    private static func findBinary(name: String) -> String? {
        let fileManager = FileManager.default
        let candidatePaths = [
            "/opt/homebrew/bin/\(name)",
            "/usr/local/bin/\(name)",
            "/usr/bin/\(name)",
             NSSearchPathForDirectoriesInDomains(.userDirectory, .allDomainsMask, true).first.map { $0 + "/bin/\(name)" } ?? ""
        ]
        
        for path in candidatePaths {
            if fileManager.fileExists(atPath: path) {
                return path
            }
        }
        return nil
    }
    
    private static func discoverModels(binaryPath: String, listCommand: [String], provider: String) async -> [AIModelInfo] {
        do {
            let output = try await AIProcessService.runCommand(
                executablePath: binaryPath,
                arguments: listCommand,
                timeout: 5.0 // Fast timeout
            )
            
            // Basic parsing: assume each line is a model name or contains it
            // Adjust logic based on actual CLI output format
            let lines = output.components(separatedBy: .newlines)
            var models: [AIModelInfo] = []
            
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty || trimmed.lowercased().contains("name") || trimmed.lowercased().contains("id") { continue }
                
                // Heuristic: take the first word as model name
                let parts = trimmed.components(separatedBy: .whitespaces)
                if let modelName = parts.first, !modelName.isEmpty {
                    models.append(AIModelInfo(
                        id: "\(provider)-\(modelName)",
                        modelName: modelName,
                        displayName: modelName.capitalized,
                        provider: provider,
                        executablePath: binaryPath
                    ))
                }
            }
            return models
        } catch {
            print("Failed to discover models for \(provider): \(error)")
            return []
        }
    }

    static func generateCoverLetter(
        jobDescription: String, 
        cvContext: String, 
        instructions: String,
        model: AIModelInfo,
        completion: @escaping (Result<String, Error>) -> Void
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
                // Determine arguments based on provider
                var args: [String] = []
                var usesStdin = false
                
                switch model.provider {
                case "gemini":
                    // gemini -m <model> --yolo "<prompt>" (usually arg based)
                    // Or check if it supports stdin. Previous code used args for everything.
                    // Let's stick to what worked before: ["-m", model, "--yolo"]
                    args = ["-m", model.modelName, "--yolo"]
                    usesStdin = false
                case "opencode":
                    // opencode run --model <model>
                    args = ["run", "--model", model.modelName]
                    usesStdin = true
                case "mistral":
                    // mistral run --model <model> (assuming)
                    args = ["run", "--model", model.modelName]
                    usesStdin = true
                default:
                    args = []
                }
                
                let input = usesStdin ? prompt : nil
                let finalArgs = usesStdin ? args : args + [prompt]
                
                print("Running \(model.executablePath) with args: \(finalArgs)")
                
                let output = try await AIProcessService.runCommand(
                    executablePath: model.executablePath,
                    arguments: finalArgs,
                    input: input,
                    timeout: 300.0
                )
                
                await MainActor.run { completion(.success(output)) }
            } catch {
                print("❌ AI Error: \(error.localizedDescription)")
                await MainActor.run { completion(.failure(error)) }
            }
        }
    }
}
