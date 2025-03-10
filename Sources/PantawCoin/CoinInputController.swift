import Cocoa

class CoinInputController: NSObject {
    private var window: NSWindow?
    private var textField: NSTextField?
    private var completionHandler: ((String?) -> Void)?
    
    func showInputDialog(withTitle title: String, message: String, completion: @escaping (String?) -> Void) {
        completionHandler = completion
        
        // Create the window
        let contentRect = NSRect(x: 0, y: 0, width: 400, height: 130)
        window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window?.center()
        window?.title = title
        
        // Create the content view
        let contentView = NSView(frame: contentRect)
        window?.contentView = contentView
        
        // Add message label
        let messageLabel = NSTextField(frame: NSRect(x: 20, y: 90, width: 360, height: 20))
        messageLabel.stringValue = message
        messageLabel.isEditable = false
        messageLabel.isBezeled = false
        messageLabel.drawsBackground = false
        contentView.addSubview(messageLabel)
        
        // Add text field for input
        textField = NSTextField(frame: NSRect(x: 20, y: 60, width: 360, height: 24))
        textField?.placeholderString = "e.g., BTC, ETH, SOL"
        contentView.addSubview(textField!)
        
        // Add buttons
        let cancelButton = NSButton(frame: NSRect(x: 190, y: 20, width: 90, height: 24))
        cancelButton.title = "Cancel"
        cancelButton.bezelStyle = .rounded
        cancelButton.target = self
        cancelButton.action = #selector(cancelButtonClicked)
        contentView.addSubview(cancelButton)
        
        let okButton = NSButton(frame: NSRect(x: 290, y: 20, width: 90, height: 24))
        okButton.title = "OK"
        okButton.bezelStyle = .rounded
        okButton.target = self
        okButton.action = #selector(okButtonClicked)
        contentView.addSubview(okButton)
        
        // Make the OK button the default button
        window?.defaultButtonCell = okButton.cell as? NSButtonCell
        
        // Show the window
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func cancelButtonClicked() {
        closeWindowAndCallCompletion(with: nil)
    }
    
    @objc private func okButtonClicked() {
        let ticker = textField?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        closeWindowAndCallCompletion(with: ticker)
    }
    
    private func closeWindowAndCallCompletion(with result: String?) {
        window?.orderOut(nil)
        window = nil
        completionHandler?(result)
        completionHandler = nil
    }
} 