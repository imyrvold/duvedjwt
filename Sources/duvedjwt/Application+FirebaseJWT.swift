import Vapor
import JWTKit
import JWT

extension Application {
    public var firebaseJwt: FirebaseJWT {
        .init(application: self)
    }
    
    public struct FirebaseJWT {
        let application: Application
        
        public func signers(on request: Request) async throws -> JWTKeyCollection {
            try await withCheckedThrowingContinuation { continuation in
                self.jwks.get(on: request).flatMapThrowing { jwks in
                    // Assuming `add(jwks:)` is an async function
                    Task {
                        let collection = try await JWTKeyCollection().add(jwks: jwks)
                        continuation.resume(returning: collection)
                    }
                }.whenFailure { error in
                    continuation.resume(throwing: error)
                }
            }
        }
        
        public var jwks: EndpointCache<JWKS> {
            self.storage.jwks
        }
        
        public var applicationIdentifier: String? {
            get {
                self.storage.applicationIdentifier
            }
            nonmutating set {
                self.storage.applicationIdentifier = newValue
            }
        }
        
        private struct Key: StorageKey, LockKey {
            typealias Value = Storage
        }

        private final class Storage: @unchecked Sendable {
            let jwks: EndpointCache<JWKS>
            var applicationIdentifier: String?
            var gSuiteDomainName: String?
            init() {
                self.jwks = .init(uri: "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com")
                self.applicationIdentifier = nil
                self.gSuiteDomainName = nil
            }
        }
        
        private var storage: Storage {
            if let existing = self.application.storage[Key.self] {
                return existing
            } else {
                let lock = self.application.locks.lock(for: Key.self)
                lock.lock()
                defer { lock.unlock() }
                if let existing = self.application.storage[Key.self] {
                    return existing
                }
                let new = Storage()
                self.application.storage[Key.self] = new
                return new
            }
        }
    }
}
