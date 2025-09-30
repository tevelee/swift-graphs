import Collections

/// A protocol for stack-like data structures.
///
/// Stack protocols define the interface for last-in-first-out (LIFO) data structures.
/// This is useful for algorithms that need to maintain a stack of elements.
public protocol StackProtocol<Element> {
    associatedtype Element

    var isEmpty: Bool { get }
    mutating func push(_ element: Element)
    mutating func pop() -> Element?
}

extension Array: StackProtocol {
    @inlinable
    public mutating func push(_ element: Element) {
        append(element)
    }
    
    @inlinable
    public mutating func pop() -> Element? {
        popLast()
    }
}

extension Deque: StackProtocol {
    @inlinable
    public mutating func push(_ element: Element) {
        append(element)
    }
    
    @inlinable
    public mutating func pop() -> Element? {
        popLast()
    }
}
