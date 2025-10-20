import Collections

/// A protocol for queue-like data structures.
public protocol QueueProtocol<Element> {
    associatedtype Element

    var isEmpty: Bool { get }
    mutating func enqueue(_ element: Element)
    mutating func dequeue() -> Element?
}

extension Deque: QueueProtocol {
    @inlinable
    public mutating func enqueue(_ element: Element) {
        append(element)
    }
    
    @inlinable
    public mutating func dequeue() -> Element? {
        popFirst()
    }
}

/// A priority queue implementation using a heap.
public struct PriorityQueue<Element: Comparable>: QueueProtocol {
    @usableFromInline
    var heap = Heap<Element>()

    @inlinable
    public init() {}

    @inlinable
    public var isEmpty: Bool {
        heap.isEmpty
    }

    @inlinable
    public mutating func enqueue(_ element: Element) {
        heap.insert(element)
    }

    @inlinable
    public mutating func dequeue() -> Element? {
        heap.popMin()
    }
}
