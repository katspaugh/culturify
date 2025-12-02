import SwiftUI

struct ContentView: View {
    @StateObject private var ollamaService = OllamaService()
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            if ollamaService.response.isEmpty {
                Text("Ask Ollama")
                    .font(.headline)
                    .padding(.top)
                
                TextEditor(text: $inputText)
                    .font(.system(size: 13))
                    .frame(height: 180)
                    .border(Color.gray.opacity(0.3), width: 1)
                    .disabled(isLoading)
                
                Button(action: submitQuery) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.7)
                            .frame(width: 100)
                    } else {
                        Text("Submit")
                            .frame(width: 100)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(inputText.isEmpty || isLoading)
            } else {
                HStack {
                    Text("Response")
                        .font(.headline)
                    Spacer()
                    Button(action: resetView) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top)
                
                ScrollView {
                    Text(ollamaService.response)
                        .font(.system(size: 13))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
                .frame(height: 230)
                .background(Color.gray.opacity(0.05))
                .border(Color.gray.opacity(0.3), width: 1)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
    
    private func submitQuery() {
        isLoading = true
        Task {
            await ollamaService.query(prompt: inputText)
            isLoading = false
        }
    }
    
    private func resetView() {
        inputText = ""
        ollamaService.response = ""
    }
}
