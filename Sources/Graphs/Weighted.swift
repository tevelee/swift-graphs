/// A protocol that defines a weighted element.
public protocol Weighted {
    /// The type of the weight, which must be comparable.
    associatedtype Weight: Comparable

    /// The weight of the element.
    var weight: Weight { get }
}

extension Weighted where Self: Comparable {
    /// Returns the weight of the element.
    @inlinable public var weight: Self { self }
}

extension Comparable where Self: Weighted {
    /// Compares two weighted elements based on their weights.
    /// - Parameters:
    ///   - lhs: The left-hand side element.
    ///   - rhs: The right-hand side element.
    /// - Returns: `true` if the weight of the left-hand side element is less than the weight of the right-hand side element, `false` otherwise.
    @inlinable public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.weight < rhs.weight
    }
}

extension Int: Weighted {}
extension UInt: Weighted {}
extension Double: Weighted {}
extension Float: Weighted {}

