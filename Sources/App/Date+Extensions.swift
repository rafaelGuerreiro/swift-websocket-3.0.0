import Foundation

extension Date {
    init?(timestamp: String) {
        if let instance = Date.timestampFormatter.date(from: timestamp) {
            self = instance
        } else {
            return nil
        }
    }

    public static var timestampFormatter: DateFormatter {
        let fmt = DateFormatter()
        fmt.timeZone = TimeZone(secondsFromGMT: 0)
        fmt.dateFormat  = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return fmt
    }

    public var timestamp: String {
        return Date.timestampFormatter.string(from: self)
    }

    public static func currentTimestamp() -> String {
        return Date().timestamp
    }
}

