import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var culturifyService = CulturifyService()
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            if culturifyService.response.isEmpty {
                CustomTextEditor(text: $inputText, onSubmit: {
                    if !inputText.isEmpty && !isLoading {
                        submitQuery()
                    }
                })
                .font(.system(size: 13))
                .frame(height: 200)
                .border(Color.gray.opacity(0.3), width: 1)
                .disabled(isLoading)
                
                Button(action: submitQuery) {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.6)
                                .frame(width: 12, height: 12)
                        }
                        Text("Culturify")
                    }
                    .frame(height: 20)
                }
                .buttonStyle(.borderedProminent)
                .disabled(inputText.isEmpty || isLoading)
            } else {
                VStack(spacing: 8) {
                    if #available(macOS 13.0, *) {
                        Text(try! AttributedString(markdown: culturifyService.response, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
                            .font(.system(size: 13))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Button(action: resetView) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("New Query")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return, modifiers: [])
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .frame(width: 400)
        .fixedSize(horizontal: false, vertical: true)
    }
    
    private func submitQuery() {
        isLoading = true
        Task {
            await culturifyService.query(prompt: "You are a text editor that corrects grammar and improves clarity. Make text sound friendly and professional but personal - use 'I' instead of 'we' when applicable. Keep the tone warm and conversational, suitable for internal team communication on Slack.\n\nIMPORTANT: Output ONLY the corrected text itself. Do not add any preamble like 'Here is the corrected text:' or explanations. Just return the corrected version directly.\n\nText to correct:\n\(inputText)")
            isLoading = false
            
            if !culturifyService.response.isEmpty {
                await MainActor.run {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(culturifyService.response, forType: .string)
                }
            }
        }
    }
    
    private func resetView() {
        inputText = ""
        culturifyService.response = ""
    }
}

struct ResponseKeyHandler: NSViewRepresentable {
    var onReturn: () -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyHandlerView()
        view.onReturn = onReturn
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let view = nsView as? KeyHandlerView {
            view.onReturn = onReturn
        }
    }
    
    class KeyHandlerView: NSView {
        var onReturn: (() -> Void)?
        
        override var acceptsFirstResponder: Bool { true }
        
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            window?.makeFirstResponder(self)
        }
        
        override func keyDown(with event: NSEvent) {
            if event.keyCode == 36 { // Return key
                onReturn?()
            } else {
                super.keyDown(with: event)
            }
        }
    }
}

struct CustomTextEditor: NSViewRepresentable {
    @Binding var text: String
    var onSubmit: () -> Void
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.font = .systemFont(ofSize: 13)
        textView.autoresizingMask = [.width, .height]
        textView.textColor = .labelColor
        textView.backgroundColor = .textBackgroundColor
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        if textView.string != text {
            textView.string = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CustomTextEditor
        
        init(_ parent: CustomTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
        
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if NSEvent.modifierFlags.contains(.shift) {
                    return false
                } else {
                    parent.onSubmit()
                    return true
                }
            }
            return false
        }
    }
}
