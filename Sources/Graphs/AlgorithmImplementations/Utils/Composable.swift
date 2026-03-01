/// A protocol for types that can be combined with other types.
///
/// ## Visitor Composition Pattern
///
/// Each algorithm's `Visitor` struct uses closure-based callbacks and conforms to `Composable`.
/// Composition follows these conventions:
///
/// - **Standard closures** (e.g., `discoverVertex`, `examineEdge`): compose by calling both
///   closures in sequence — `self.callback?(args); other.callback?(args)`.
/// - **Boolean callbacks** (e.g., `shouldTraverse`): compose with AND semantics —
///   `(self.callback?(args) ?? true) && (other.callback?(args) ?? true)`.
///
/// Each algorithm's `Visitor` struct is defined alongside the algorithm implementation.
/// The `Composable` extension for each visitor goes in a separate `*Visitor+Composition.swift` file.
public protocol Composable {
    associatedtype Other
    
    func combined(with other: Other) -> Self
}

extension Composable where Other == Self {
    @inlinable
    public func combined(with other: Self?) -> Self {
        if let other {
            combined(with: other)
        } else {
            self
        }
    }
}

extension Never: Composable {
    @inlinable
    public func combined(with other: Never) -> Never {}
}
