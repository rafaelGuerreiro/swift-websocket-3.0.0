import Foundation
import Vapor
import WebSocket
import HTTP

extension Request {
    public func upgradeToWebSocket(body: @escaping (WebSocket) throws -> Void) throws -> Response {
        onUpgrade = { client in
            let ws = WebSocket(client: client)
            try? body(ws)
        }

        return try WebSocket.upgradeResponse(for: self)
    }
}
