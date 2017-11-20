import Foundation
import Redis
import Async

struct MessageInputData: Codable {
    let message: String
    let sent: Date
}

struct RedisMessage: Codable {
    let username: String
    let message: String
    let sent: Date

    init(username: String, input: MessageInputData) {
        self.username = username
        self.message = input.message
        self.sent = input.sent
    }
}

struct MessageOutputData: Codable {
    let username: String
    let message: String
    let sent: Date
    let received: Date

    init(_ redis: RedisMessage) {
        self.username = redis.username
        self.message = redis.message
        self.sent = redis.sent
        self.received = Date()
    }
}

struct RedisMessageError: Error {
    let message: String
}

extension RedisClient {
    @discardableResult func publish(_ message: RedisMessage, to channel: String) -> Future<Int> {
        guard let json = message.toJson() else {
            return Future(error: RedisMessageError(message: "Unable to convert RedisMessage into a json."))
        }
        return self.publish(RedisData.basicString(json), to: channel)
    }
}

extension Async.OutputStream where Output == ChannelMessage {
    @discardableResult func onRedisMessage(_ handler: @escaping (RedisMessage, RedisData) -> Void) -> Self {
        return drain({ (data) in
            guard let json = data.message.string,
                let redisMessage: RedisMessage = RedisMessage.from(json: json) else {
                    return
            }

            handler(redisMessage, data.message)
        })
    }
}

extension Encodable {
    func toJson() -> String? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(Date.timestampFormatter)
        if let encoded: Data = try? encoder.encode(self) {
            return encoded.makeString()
        }

        return nil
    }
}

extension Decodable {
    static func from<T: Decodable>(json: String) -> T? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(Date.timestampFormatter)

        if let stringData = json.data(using: .utf8),
            let data: T = try? decoder.decode(T.self, from: stringData) {
            return data
        }

        return nil
    }
}

extension Sequence where Iterator.Element == UInt8 {
    /// Converts a slice of bytes to
    /// string. Courtesy of @vzsg
    public func makeString() -> String {
        let array = Array(self) + [0]

        return array.withUnsafeBytes { rawBuffer in
            guard let pointer = rawBuffer.baseAddress?.assumingMemoryBound(to: CChar.self) else { return nil }
            return String(validatingUTF8: pointer)
        } ?? ""
    }
}
