import SwiftUI
import AppKit
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var hotKeyRef: EventHotKeyRef?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = createCustomIcon()
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        let contentView = ContentView()
        popover = NSPopover()
        popover?.behavior = .transient
        let hostingController = NSHostingController(rootView: contentView)
        hostingController.sizingOptions = [.intrinsicContentSize]
        popover?.contentViewController = hostingController
        
        registerGlobalHotkey()
    }
    
    func registerGlobalHotkey() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        let selfPointer = UnsafeMutablePointer<AppDelegate>.allocate(capacity: 1)
        selfPointer.initialize(to: self)
        
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            guard let userData = userData else { return noErr }
            let appDelegate = userData.assumingMemoryBound(to: AppDelegate.self).pointee
            
            DispatchQueue.main.async {
                appDelegate.handleHotkey()
            }
            
            return noErr
        }, 1, &eventType, selfPointer, nil)
        
        // Register Cmd+Shift+Space
        var hotKeyID = EventHotKeyID(signature: OSType(0x4F4C4C4D), id: 1) // "OLLM"
        let keyCode: UInt32 = 49 // Space key
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)
        
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }
    
    func handleHotkey() {
        togglePopover()
    }
    
    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }
        
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
    
    func createCustomIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        let context = NSGraphicsContext.current?.cgContext
        context?.setFillColor(NSColor.labelColor.cgColor)
        
        let rect = NSRect(x: 3, y: 3, width: 12, height: 12)
        let path = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)
        path.fill()
        
        context?.setFillColor(NSColor.controlBackgroundColor.cgColor)
        let innerRect = NSRect(x: 6, y: 8, width: 6, height: 2)
        let innerPath = NSBezierPath(rect: innerRect)
        innerPath.fill()
        
        image.unlockFocus()
        image.isTemplate = true
        
        return image
    }
}
