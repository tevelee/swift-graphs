import Collections

protocol QueueProtocol<Element> {
    associatedtype Element

    var isEmpty: Bool { get }
    mutating func enqueue(_ element: Element)
    mutating func dequeue() -> Element?
}

extension Deque: QueueProtocol {
    mutating func enqueue(_ element: Element) {
        append(element)
    }
    
    mutating func dequeue() -> Element? {
        popFirst()
    }
}

struct PriorityQueue<Element: Comparable>: QueueProtocol {
    private var heap = Heap<Element>()

    var isEmpty: Bool {
        heap.isEmpty
    }

    mutating func enqueue(_ element: Element) {
        heap.insert(element)
    }

    mutating func dequeue() -> Element? {
        heap.popMin()
    }
}
