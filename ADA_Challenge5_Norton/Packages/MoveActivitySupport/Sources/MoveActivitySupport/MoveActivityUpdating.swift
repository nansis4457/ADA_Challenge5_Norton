import Foundation
import SweatDomain

public enum MoveActivityError: Error, Sendable, Equatable {
    case disabled
    case unsupported
}

public protocol MoveActivityUpdating: AnyObject {
    var isAvailable: Bool { get }
    func start(session: MoveSession, progress: MoveProgress) async throws
    @discardableResult
    func update(progress: MoveProgress) async -> Bool
    func end(finalProgress: MoveProgress?) async
}

public final class UnavailableMoveActivityClient: MoveActivityUpdating {
    public init() {}
    public var isAvailable: Bool { false }
    public func start(session: MoveSession, progress: MoveProgress) async throws {
        throw MoveActivityError.unsupported
    }
    public func update(progress: MoveProgress) async -> Bool { false }
    public func end(finalProgress: MoveProgress?) async {}
}
