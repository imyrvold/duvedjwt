import Vapor
import JWTKit

extension Request {
    public var firebaseJwt: FirebaseJWT {
        .init(request: self)
    }
    
    public struct FirebaseJWT {
        let request: Request
        
        public func verify(applicationIdentifier: String? = nil) async throws -> FirebaseJWTPayload {
            guard let token = self.request.headers.bearerAuthorization?.token else {
                self.request.logger.error("Request is missing JWT bearer header.")
                throw Abort(.unauthorized)
            }
            return try await self.verify(token, applicationIdentifier: applicationIdentifier)
        }

        
        public func verify(_ message: String, applicationIdentifier: String? = nil ) async throws -> FirebaseJWTPayload {
            try await self.verify([UInt8](message.utf8), applicationIdentifier: applicationIdentifier)
        }
        
        public func verify<Message: Sendable>(_ message: Message, applicationIdentifier: String? = nil) async throws -> FirebaseJWTPayload where Message: DataProtocol {
            let signers = try await self.request.application.firebaseJwt.signers(on: self.request)
            let token = try await signers.verify(message, as: FirebaseJWTPayload.self)
            if let applicationIdentifier {
                try token.audience.verifyIntendedAudience(includes: applicationIdentifier)
            }
            return token
        }
    }
}
