import Foundation

class CulturifyService: ObservableObject {
    @Published var response: String = ""
    
    private func stripANSICodes(from text: String) -> String {
        var cleaned = text
        
        // Remove ANSI escape codes
        let ansiPattern = "\\x1B(?:[@-Z\\\\-_]|\\[[0-?]*[ -/]*[@-~])"
        if let regex = try? NSRegularExpression(pattern: ansiPattern, options: []) {
            let range = NSRange(cleaned.startIndex..., in: cleaned)
            cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: range, withTemplate: "")
        }
        
        // Remove spinner characters (Unicode Braille patterns used by ollama)
        let spinnerPattern = "[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏]"
        if let regex = try? NSRegularExpression(pattern: spinnerPattern, options: []) {
            let range = NSRange(cleaned.startIndex..., in: cleaned)
            cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: range, withTemplate: "")
        }
        
        return cleaned
    }
    
    private func findCopilotPath() -> String? {
        let possiblePaths = [
            "/opt/homebrew/bin/gh",
            "/usr/local/bin/gh",
            "/usr/bin/gh"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        let whichProcess = Process()
        whichProcess.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        whichProcess.arguments = ["gh"]
        
        let pipe = Pipe()
        whichProcess.standardOutput = pipe
        
        do {
            try whichProcess.run()
            whichProcess.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !path.isEmpty {
                return path
            }
        } catch {}
        
        return nil
    }
    
    private func findOllamaPath() -> String? {
        let possiblePaths = [
            "/opt/homebrew/bin/ollama",
            "/usr/local/bin/ollama",
            "/usr/bin/ollama"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        let whichProcess = Process()
        whichProcess.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        whichProcess.arguments = ["ollama"]
        
        let pipe = Pipe()
        whichProcess.standardOutput = pipe
        
        do {
            try whichProcess.run()
            whichProcess.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !path.isEmpty {
                return path
            }
        } catch {}
        
        return nil
    }
    
    func query(prompt: String) async {
        // Try Copilot CLI first
        if let copilotPath = findCopilotPath() {
            await queryCopilot(path: copilotPath, prompt: prompt)
        } else if let ollamaPath = findOllamaPath() {
            await queryOllama(path: ollamaPath, prompt: prompt)
        } else {
            await MainActor.run {
                self.response = "Error: Neither GitHub Copilot CLI nor Ollama found. Please install one of them."
            }
        }
    }
    
    private func queryCopilot(path: String, prompt: String) async {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = ["copilot", "--prompt", prompt, "--model", "claude-haiku-4.5"]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? "Error: No output received"
            
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let cleanedOutput = stripANSICodes(from: output)
                await MainActor.run {
                    self.response = cleanedOutput.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } else {
                // Copilot failed, fall back to Ollama
                if let ollamaPath = findOllamaPath() {
                    await queryOllama(path: ollamaPath, prompt: prompt)
                } else {
                    await MainActor.run {
                        self.response = "Error: Copilot CLI failed and Ollama not found."
                    }
                }
            }
        } catch {
            // Copilot failed, fall back to Ollama
            if let ollamaPath = findOllamaPath() {
                await queryOllama(path: ollamaPath, prompt: prompt)
            } else {
                await MainActor.run {
                    self.response = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func queryOllama(path: String, prompt: String) async {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = ["run", "--nowordwrap", "--hidethinking", "llama3.1:8b", prompt]
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        
        do {
            try process.run()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? "Error: No output received"
            
            process.waitUntilExit()
            
            let cleanedOutput = stripANSICodes(from: output)
            
            await MainActor.run {
                self.response = cleanedOutput.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            await MainActor.run {
                self.response = "Error: \(error.localizedDescription)"
            }
        }
    }
}
