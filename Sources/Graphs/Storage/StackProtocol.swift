import Collections

protocol StackProtocol<Element> {
    associatedtype Element

    var isEmpty: Bool { get }
    mutating func push(_ element: Element)
    mutating func pop() -> Element?
}

extension Array: StackProtocol {
    mutating func push(_ element: Element) {
        append(element)
    }
    
    mutating func pop() -> Element? {
        popLast()
    }
}

extension Deque: StackProtocol {
    mutating func push(_ element: Element) {
        append(element)
    }
    
    mutating func pop() -> Element? {
        popLast()
    }
}
