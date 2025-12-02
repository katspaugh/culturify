import Foundation

class OllamaService: ObservableObject {
    @Published var response: String = ""
    
    func query(prompt: String) async {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/ollama")
        process.arguments = ["run", "llama3.1:8b", prompt]
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        
        do {
            try process.run()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? "Error: No output received"
            
            process.waitUntilExit()
            
            await MainActor.run {
                self.response = output.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            await MainActor.run {
                self.response = "Error: \(error.localizedDescription)"
            }
        }
    }
}
