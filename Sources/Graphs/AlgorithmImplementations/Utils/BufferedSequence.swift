/// A sequence that wraps another sequence and collects elements into a buffer
/// based on a configuration function. This is useful for transforming sequences
/// that emit elements through callbacks/visitors into standard sequences.
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

/// Shared buffer that can be captured by closures
final class SharedBuffer<Element> {
    var elements: [Element] = []
    
    func append(_ element: Element) {
        elements.append(element)
    }
}

/// Iterator for BufferedSequence
struct BufferedIterator<Base: Sequence, Element>: IteratorProtocol {
    private var baseIterator: Base.Iterator
    private let buffer: SharedBuffer<Element>
    
    init(base: Base, configure: @escaping (SharedBuffer<Element>, Base) -> Base) {
        self.buffer = SharedBuffer<Element>()
        let configuredBase = configure(buffer, base)
        self.baseIterator = configuredBase.makeIterator()
    }
    
    mutating func next() -> Element? {
        // Return any buffered elements first
        if !buffer.elements.isEmpty {
            return buffer.elements.removeFirst()
        }
        
        // Advance base sequence until buffer gets populated or we exhaust the sequence
        while baseIterator.next() != nil {
            // Check if the visitor callback added elements to the buffer
            if !buffer.elements.isEmpty {
                return buffer.elements.removeFirst()
            }
        }
        
        // Base sequence exhausted and no buffered elements
        return nil
    }
}

extension BufferedSequence {
    /// Creates a BufferedSequence that collects elements using a simple callback
    static func collecting(
        from base: Base,
        whenEmitted: @escaping (SharedBuffer<Element>, Base) -> Base
    ) -> BufferedSequence<Base, Element> {
        BufferedSequence(base: base, configure: whenEmitted)
    }
}
