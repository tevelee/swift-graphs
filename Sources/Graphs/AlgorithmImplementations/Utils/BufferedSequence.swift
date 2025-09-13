struct BufferedSequence<Base: Sequence, Element>: Sequence {
    let base: Base
    let configure: (SharedBuffer<Element>, Base) -> Base
    
    init(base: Base, configure: @escaping (SharedBuffer<Element>, Base) -> Base) {
        self.base = base
        self.configure = configure
    }
    
    func makeIterator() -> BufferedIterator<Base, Element> {
        BufferedIterator(base: base, configure: configure)
    }
}

final class SharedBuffer<Element> {
    var elements: [Element] = []
    
    func append(_ element: Element) {
        elements.append(element)
    }
}

struct BufferedIterator<Base: Sequence, Element>: IteratorProtocol {
    private var baseIterator: Base.Iterator
    private let buffer: SharedBuffer<Element>
    
    init(base: Base, configure: @escaping (SharedBuffer<Element>, Base) -> Base) {
        self.buffer = SharedBuffer<Element>()
        let configuredBase = configure(buffer, base)
        self.baseIterator = configuredBase.makeIterator()
    }
    
    mutating func next() -> Element? {
        if !buffer.elements.isEmpty {
            return buffer.elements.removeFirst()
        }
        while baseIterator.next() != nil {
            if !buffer.elements.isEmpty {
                return buffer.elements.removeFirst()
            }
        }
        return nil
    }
}

extension BufferedSequence {
    static func collecting(
        from base: Base,
        whenEmitted: @escaping (SharedBuffer<Element>, Base) -> Base
    ) -> BufferedSequence<Base, Element> {
        BufferedSequence(base: base, configure: whenEmitted)
    }
}
