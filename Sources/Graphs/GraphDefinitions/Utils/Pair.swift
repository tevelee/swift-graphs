/// A composite vertex descriptor for graph products.
///
/// `Pair<A, B>` represents a vertex in any of the four classical graph products.
/// It is `Hashable` whenever both components are, satisfying the requirements
/// of all graph algorithm color maps and visited-vertex sets.
public struct Pair<A: Hashable, B: Hashable>: Hashable {
    /// The first component of the pair.
    public let first: A
    /// The second component of the pair.
    public let second: B

    @inlinable
    public init(_ first: A, _ second: B) {
        self.first = first
        self.second = second
    }
}

extension Pair: Sendable where A: Sendable, B: Sendable {}

extension Pair: CustomStringConvertible {
    @inlinable public var description: String { "(\(first), \(second))" }
}
