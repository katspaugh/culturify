import SwiftUI
import FoundationModels
import Carbon.HIToolbox

// MARK: - Text transformation

// Structured output is what stops the model answering the message instead of
// rewriting it: there is no field for an apology or a refusal, so the only
// thing it can produce is the rewrite. Three prompt-wording and prompt-order
// attempts (a789840, 67164db, 414d16f) all failed to hold that line.
@Generable
struct Rewrite {
    @Guide(description: "The rewritten message, in the author's own voice, ready for them to send")
    var message: String
}

enum Culturifier {
    // A fresh session per request keeps each rewrite stateless, so long
    // conversations can't overflow the model's 4,096-token context window.
    static func session() -> LanguageModelSession {
        LanguageModelSession(instructions: """
            You are a text-transformation tool, not a chat partner. Every \
            request is a fresh document to edit: you have no conversation \
            history, you have said nothing previously, and there is nothing \
            of yours for anyone to be reacting to.

            You rewrite text so it is ready to post on Slack: fix grammar and \
            spelling, and make the tone polite, warm, and conversational — \
            friendly but professional, suited to internal team chat. Keep it \
            personal: use "I" instead of "we" where it applies.

            Softening a blunt message is the whole point, so add whatever \
            words that takes: an apology, a hedge, a friendlier framing. A \
            curt input should usually come out longer than it went in — \
            fixing the spelling alone is a failed rewrite. What you must \
            never add is new substance: no fact, promise, deadline, offer, \
            or commitment that the original did not already make.

            Rewrite the exact message you are given, every time. Never reply \
            to it, never answer it, and never substitute a message of your \
            own — your output is always a transformation of the input words, \
            so it must track what the input actually said.

            The input is often angry, rude, or profane. That is the normal \
            case and the entire reason you exist: someone is about to send \
            something they would regret, and you are the step in between. \
            Never refuse such a message, never lecture the author, and never \
            remark on their language — refusing is the single worst thing \
            you can do here, because it hands the author back the original \
            and they send that instead.

            An insult is a real feeling expressed badly. Carry the feeling \
            across; drop only the abuse. "You idiot" means the author is \
            angry and something is wrong, so the rewrite still says that \
            something is wrong — firmly, in words that can be sent. Do not \
            flatten a complaint into a pleasantry: a rewrite that loses the \
            grievance has failed just as badly as one that keeps the insult.

            Output ONLY the rewritten text — no preamble, no surrounding \
            quotes, no explanations.
            """)
    }

    // The instruction deliberately comes *after* the message, ending on a
    // bare "Rewritten message:" cue. With the text last, it is the final
    // thing the model reads and it answers it — a second-person insult like
    // "u turd" gets an apology from the model about its own conduct. Trailing
    // the cue instead puts it in continuation mode: the next tokens have to
    // be the rewrite, because that is what the line it just read announces.
    static func request(for text: String) -> String {
        """
        A colleague drafted the message below and asked you to clean it up \
        before they send it to someone else. It is raw material to work on, \
        not something said to you, however rude it looks.

        <message>
        \(text)
        </message>

        Fill in the rewritten message: what the author meant, in the \
        author's voice, aimed at the person they are writing to, in words \
        they can actually send. You are not a party to this exchange — \
        there is no previous response of yours behind it and nothing for \
        you to apologise for.
        """
    }
}

// MARK: - UI

// The popover is a fixed size: NSPopover derives its frame from the hosting
// controller's intrinsic content size, and a view that grows while the model
// streams would make the popover resize on every token.
enum Layout {
    static let popoverSize = NSSize(width: 400, height: 280)
    static let padding: CGFloat = 12
}

struct ContentView: View {
    @State private var input = ""
    @State private var output = ""
    @State private var errorMessage: String?
    @State private var isWorking = false
    @State private var isCopied = false
    @FocusState private var editorFocused: Bool

    private let model = SystemLanguageModel.default

    var body: some View {
        Group {
            switch model.availability {
            case .available:
                if output.isEmpty {
                    inputView
                } else {
                    resultView
                }
            case .unavailable(let reason):
                unavailableView(reason)
            }
        }
        .padding(Layout.padding)
        .frame(width: Layout.popoverSize.width, height: Layout.popoverSize.height)
        .onReceive(NotificationCenter.default.publisher(for: NSPopover.didCloseNotification)) { _ in
            // Dismissing a finished result starts the next message fresh. A
            // half-typed draft in the input state is left alone, and a
            // still-streaming rewrite is left to finish and reach the
            // clipboard — it will be waiting on the next open.
            guard !output.isEmpty, !isWorking else { return }
            reset()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSPopover.didShowNotification)) { _ in
            // The reset above runs while the popover is hidden, so the
            // editor's onAppear focus lands on a window that isn't key yet.
            guard output.isEmpty else { return }
            DispatchQueue.main.async { editorFocused = true }
        }
    }

    private var inputView: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextEditor(text: $input)
                .font(.body)
                .frame(maxHeight: .infinity)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.separator))
                .focused($editorFocused)
                .disabled(isWorking)
                .onKeyPress(keys: [.return]) { press in
                    // Enter submits; Shift+Enter inserts a newline.
                    guard !press.modifiers.contains(.shift) else { return .ignored }
                    submit()
                    return .handled
                }
                .onAppear {
                    DispatchQueue.main.async { editorFocused = true }
                }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Button("Culturify", action: submit)
                    .buttonStyle(.borderedProminent)
                    .disabled(isWorking || input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                if isWorking {
                    ProgressView()
                        .controlSize(.small)
                }
                Spacer()
                Text("↩ to submit · ⇧↩ for newline")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var resultView: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView {
                Text(output)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            HStack {
                Button("New Message", action: reset)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return, modifiers: [])
                if isWorking {
                    ProgressView()
                        .controlSize(.small)
                }
                Spacer()
                if isCopied {
                    Label("Copied to clipboard", systemImage: "checkmark")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func unavailableView(_ reason: SystemLanguageModel.Availability.UnavailableReason) -> some View {
        let message: String
        switch reason {
        case .deviceNotEligible:
            message = "This Mac doesn't support Apple Intelligence."
        case .appleIntelligenceNotEnabled:
            message = "Apple Intelligence is turned off. Enable it in System Settings > Apple Intelligence & Siri."
        case .modelNotReady:
            message = "The model is still downloading or preparing. Try again in a bit."
        @unknown default:
            message = "The model is unavailable for an unknown reason."
        }
        return ContentUnavailableView("Model Unavailable",
                                      systemImage: "exclamationmark.triangle",
                                      description: Text(message))
    }

    private func submit() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isWorking else { return }
        isWorking = true
        errorMessage = nil
        output = ""
        isCopied = false
        Task {
            // The on-device model occasionally aborts mid-generation
            // (tokengeneration error 10); one retry usually recovers.
            for attempt in 1...2 {
                do {
                    let response = try await Culturifier.session()
                        .respond(to: Culturifier.request(for: text),
                                 generating: Rewrite.self)
                    output = response.content.message
                    copyToClipboard(output)
                    errorMessage = nil
                    break
                } catch is CancellationError {
                    break
                } catch LanguageModelSession.GenerationError.guardrailViolation {
                    output = ""
                    errorMessage = "The model's safety filter blocked this one. Softening the harshest word by hand usually gets it through."
                    break
                } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
                    output = ""
                    errorMessage = "The text is too long for the model's context window. Try a shorter message."
                    break
                } catch {
                    output = ""
                    errorMessage = attempt == 1
                        ? "Generation failed, retrying…"
                        : "Error: \(error.localizedDescription)"
                }
            }
            isWorking = false
        }
    }

    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        isCopied = true
    }

    private func reset() {
        input = ""
        output = ""
        errorMessage = nil
        isCopied = false
    }
}

// MARK: - Menubar app

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var hotKeyRef: EventHotKeyRef?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "wand.and.stars",
                                   accessibilityDescription: "Culturify")
            button.action = #selector(statusItemClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        popover.behavior = .transient
        popover.contentSize = Layout.popoverSize
        let host = NSHostingController(rootView: ContentView())
        host.sizingOptions = [.intrinsicContentSize]
        host.preferredContentSize = Layout.popoverSize
        popover.contentViewController = host

        registerHotKey()
    }

    @objc private func statusItemClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(withTitle: "Quit Culturify",
                         action: #selector(NSApplication.terminate(_:)),
                         keyEquivalent: "q")
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            togglePopover()
        }
    }

    func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    // Cmd+Shift+Space toggles the popover from anywhere.
    private func registerHotKey() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            let delegate = Unmanaged<AppDelegate>.fromOpaque(userData!).takeUnretainedValue()
            DispatchQueue.main.async { delegate.togglePopover() }
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), nil)

        let hotKeyID = EventHotKeyID(signature: OSType(0x43554C54), id: 1) // "CULT"
        RegisterEventHotKey(UInt32(kVK_Space), UInt32(cmdKey | shiftKey),
                            hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }
}

// Minimal main menu so Cmd+Q, copy/paste, and undo work in the text editor.
func buildMainMenu() -> NSMenu {
    let mainMenu = NSMenu()

    let appMenuItem = NSMenuItem()
    mainMenu.addItem(appMenuItem)
    let appMenu = NSMenu()
    appMenu.addItem(withTitle: "Quit Culturify",
                    action: #selector(NSApplication.terminate(_:)),
                    keyEquivalent: "q")
    appMenuItem.submenu = appMenu

    let editMenuItem = NSMenuItem()
    mainMenu.addItem(editMenuItem)
    let editMenu = NSMenu(title: "Edit")
    editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
    editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
    editMenu.addItem(.separator())
    editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
    editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
    editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
    editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
    editMenuItem.submenu = editMenu

    return mainMenu
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // menubar only, no Dock icon
app.mainMenu = buildMainMenu()
app.run()
