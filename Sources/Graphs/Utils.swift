/// A protocol that defines a container for elements.
protocol Container<Element> {
    /// The type of elements contained in the container.
    associatedtype Element

    /// An array of elements contained in the container.
    var elements: [Element] { get }
}

extension Array: Container {
    /// An array of elements contained in the array.
    @inlinable var elements: [Element] { self }
}

/// Returns the non-negative modulo of `lhs` by `rhs`.
/// - Parameters:
///   - lhs: The dividend.
///   - rhs: The divisor.
/// - Returns: The non-negative remainder of `lhs` divided by `rhs`.
@inlinable func nonNegativeModulo(of lhs: Int, by rhs: Int) -> Int {
    let result = lhs % rhs
    return result >= 0 ? result : result + rhs
}

extension Collection {
    /// Returns the element at the specified position if it is within bounds, otherwise `nil`.
    /// - Parameter position: The position of the element to retrieve.
    /// - Returns: The element at the specified position if it is within bounds, otherwise `nil`.
    @inlinable subscript(safe position: Index) -> Element? where Index == Int {
        let index = self.index(startIndex, offsetBy: position)
        return indices.contains(index) ? self[index] : nil
    }
}
