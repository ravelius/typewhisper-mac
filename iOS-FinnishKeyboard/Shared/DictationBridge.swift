import Foundation

enum DictationBridge {
    static let groupID = "group.fi.klik.sanelu"
    private static let requestKey = "dictation.request"
    private static let resultIDKey = "dictation.result.id"
    private static let resultTextKey = "dictation.result.text"
    private static let consumedKey = "dictation.result.consumed"

    static var store: UserDefaults? { UserDefaults(suiteName: groupID) }

    @discardableResult
    static func request() -> String {
        let id = UUID().uuidString
        store?.set(id, forKey: requestKey)
        return id
    }

    static var currentRequest: String? { store?.string(forKey: requestKey) }

    static func finish(_ text: String, for id: String) {
        guard !text.isEmpty else { return }
        store?.set(text, forKey: resultTextKey)
        store?.set(id, forKey: resultIDKey) // Commit marker written last.
    }

    static func takeResult(for id: String) -> String? {
        guard let store,
              store.string(forKey: resultIDKey) == id,
              store.string(forKey: consumedKey) != id,
              let text = store.string(forKey: resultTextKey), !text.isEmpty else { return nil }
        store.set(id, forKey: consumedKey)
        return text
    }
}
