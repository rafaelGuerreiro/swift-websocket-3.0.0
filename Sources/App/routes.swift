import Routing
import Vapor
import WebSocket
import HTTP
import Redis
import TCP
import Async
import Foundation
import Leaf

/// Register your application's routes here.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#routesswift)
final class Routes: RouteCollection {
    /// Use this to create any services you may
    /// need for your routes.
    let app: Application

    /// Create a new Routes collection with
    /// the supplied application.
    init(app: Application) {
        self.app = app
    }

    /// See RouteCollection.boot
    func boot(router: Router) throws {
        router.get("/") { req in
            return try self.app.make(ViewRenderer.self).make("index.leaf", context: req, on: req)
        }

        router.get("chat", String.parameter) { req in
            return try req.parameters.next(String.self).map { (username: String) -> Response in
                return try req.upgradeToWebSocket() { (websocket: WebSocket) in
                    try WebsocketServer.register(username: username, websocket: websocket)
                }
            }
        }
    }
}
