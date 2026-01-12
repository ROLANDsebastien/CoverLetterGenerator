import Foundation

/// Centralized service to execute AI CLI processes
class AIProcessService {
    
    enum AIProcessError: Error, LocalizedError {
        case binaryNotFound(path: String)
        case executionFailed(details: String)
        case timeout
        case emptyOutput(details: String)
        
        var errorDescription: String? {
            switch self {
            case .binaryNotFound(let path):
                return "AI CLI binary not found at \(path). Please ensure it is installed via Homebrew."
            case .executionFailed(let details):
                return "AI execution failed: \(details)"
            case .timeout:
                return "The AI operation timed out."
            case .emptyOutput(let details):
                return "The AI returned no output." + (details.isEmpty ? "" : "\nDetails: \(details)")
            }
        }
    }
    
    private static func sanitize(_ string: String) -> String {
        return string.replacingOccurrences(of: "\0", with: "")
    }
    
    static func runCommand(
        executablePath: String,
        arguments: [String],
        input: String? = nil,
        timeout: TimeInterval = 60.0
    ) async throws -> String {
        
        let fileManager = FileManager.default
        let sanitizedExecutablePath = sanitize(executablePath)
        let sanitizedArguments = arguments.map { sanitize($0) }
        
        guard fileManager.fileExists(atPath: sanitizedExecutablePath) else {
            throw AIProcessError.binaryNotFound(path: sanitizedExecutablePath)
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: sanitizedExecutablePath)
        process.arguments = sanitizedArguments
        
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = (env["PATH"] ?? "") + ":/opt/homebrew/bin:/usr/local/bin"
        env["HOME"] = fileManager.homeDirectoryForCurrentUser.path
        
        // PATH and HOME are already configured above
        
        var sanitizedEnv: [String: String] = [:]
        for (key, value) in env {
            sanitizedEnv[sanitize(key)] = sanitize(value)
        }
        process.environment = sanitizedEnv
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        if input != nil {
            process.standardInput = Pipe()
        } else {
            process.standardInput = FileHandle.nullDevice
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try process.run()
                
                if let input = input, let data = sanitize(input).data(using: .utf8) {
                    if let inputPipe = process.standardInput as? Pipe {
                        DispatchQueue.global(qos: .userInitiated).async {
                            try? inputPipe.fileHandleForWriting.write(contentsOf: data)
                            try? inputPipe.fileHandleForWriting.close()
                        }
                    }
                }
                
                let timeoutTask = Task {
                    try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                    if process.isRunning {
                        process.terminate()
                    }
                }
                
                process.terminationHandler = { process in
                    timeoutTask.cancel()
                    
                    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    
                    let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let rawErrorOutput = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    
                    let errorOutput = rawErrorOutput.components(separatedBy: .newlines)
                        .filter { line in
                            let l = line.lowercased()
                            return !l.contains("[warn]") && 
                                   !l.contains("skipping unreadable directory") && 
                                   !l.contains("loaded cached credentials") &&
                                   !l.contains("loading extension") &&
                                   !line.isEmpty
                        }
                        .joined(separator: "\n")
                    
                    if process.terminationStatus == 0 {
                        if output.isEmpty {
                            continuation.resume(throwing: AIProcessError.emptyOutput(details: errorOutput))
                        } else {
                            continuation.resume(returning: output)
                        }
                    } else if process.terminationReason == .uncaughtSignal && process.terminationStatus == 15 {
                        continuation.resume(throwing: AIProcessError.timeout)
                    } else {
                        continuation.resume(throwing: AIProcessError.executionFailed(details: errorOutput.isEmpty ? "Exit code \(process.terminationStatus)" : errorOutput))
                    }
                }
                
            } catch {
                continuation.resume(throwing: AIProcessError.executionFailed(details: error.localizedDescription))
            }
        }
    }
}
