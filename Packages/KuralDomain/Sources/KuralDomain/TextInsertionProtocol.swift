import Foundation

public protocol TextInsertionProtocol {
    func insertText(_ text: String) async throws
}
