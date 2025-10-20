import Foundation

/// A protocol for types that can be combined with other types.
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
