import AppKit

/// Manages the macOS clipboard (NSPasteboard) to snapshot, inject, and restore contents.
public final class ClipboardManager {
    private let pasteboard = NSPasteboard.general
    private var snapshot: [NSPasteboardItem]?
    
    public init() {}
    
    /// Snapshots the current pasteboard contents.
    public func snapshotContents() {
        snapshot = pasteboard.pasteboardItems?.compactMap { item in
            let newItem = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    newItem.setData(data, forType: type)
                }
            }
            return newItem
        }
    }
    
    /// Restores the previously snapshotted pasteboard contents.
    public func restoreContents() {
        guard let snapshot = snapshot else { return }
        pasteboard.clearContents()
        pasteboard.writeObjects(snapshot)
        self.snapshot = nil
    }
    
    /// Injects new text into the pasteboard.
    public func setString(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
