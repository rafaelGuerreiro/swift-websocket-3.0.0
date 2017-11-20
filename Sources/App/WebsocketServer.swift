import Foundation
import Redis
import TCP
import WebSocket

fileprivate let subscriberQueue = DispatchQueue(label: "redis_queue")
fileprivate let publisher = try? RedisClient.connect(worker: DispatchQueue(label: "redis_publish_queue"))

fileprivate let redisChannel = "chat_channel"

class WebsocketServer {
    private static var connections = [String : WebsocketServer]()

    private let username: String
    private let websocket: WebSocket

    private init(username: String, websocket: WebSocket) throws {
        self.username = username
        self.websocket = websocket

        try subscribe()
        websocket.onText(self.onText(json:))
    }

    static func register(username: String, websocket: WebSocket) throws {
        connections[username] = try WebsocketServer(username: username, websocket: websocket)
    }

    private func onText(json: String) {
        if let input: MessageInputData = MessageInputData.from(json: json) {
            let message = RedisMessage(username: self.username, input: input)
            publish(message)
        }
    }

    private func publish(_ message: RedisMessage) {
        _ = publisher?.do { client in
            client.publish(message, to: redisChannel)
        }
    }

    private func subscribe() throws {
        let _ = try RedisClient.connect(worker: subscriberQueue).do { client in
            client.subscribe(to: redisChannel).onRedisMessage { message, _ in
                let output = MessageOutputData(message)
                if let outputJson = output.toJson() {
                    self.websocket.send(outputJson)
                }
            }
        }
    }
}
