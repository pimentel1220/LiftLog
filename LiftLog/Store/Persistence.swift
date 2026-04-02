import Foundation

struct PersistenceController {
    private let fileURL: URL

    init(filename: String = "LiftLogData.json") {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        fileURL = directory.appendingPathComponent(filename)
    }

    func load() -> PersistedAppState? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder.liftLog.decode(PersistedAppState.self, from: data)
    }

    func lastSavedAt() -> Date? {
        let values = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey])
        return values?.contentModificationDate
    }

    @discardableResult
    func save(_ state: PersistedAppState) -> Bool {
        guard let data = try? JSONEncoder.liftLog.encode(state) else { return false }
        do {
            try data.write(to: fileURL, options: [.atomic])
            return true
        } catch {
            return false
        }
    }
}

extension JSONEncoder {
    static var liftLog: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var liftLog: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
