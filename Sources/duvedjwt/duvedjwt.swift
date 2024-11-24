import Vapor
import JWT

final public class duvedjwt: Middleware {
    
    public init() {}
    
    public func respond(to request: Request, chainingTo next: Responder) async throws -> FirebaseJWTPayload {
        try await request.firebaseJwt.verify()
    }

    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        let promise = request.eventLoop.makePromise(of: Response.self)
        Task {
            do {
                let _ = try await request.firebaseJwt.verify()
                // Wait for the future to complete and get the actual Response
                let response = try await next.respond(to: request).get()
                promise.succeed(response)
            } catch {
                promise.fail(error)
            }
        }
        return promise.futureResult
    }
}
