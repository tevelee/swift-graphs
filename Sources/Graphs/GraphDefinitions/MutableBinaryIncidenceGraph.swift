protocol MutableBinaryIncidenceGraph: BinaryIncidenceGraph, MutableGraph {
    @discardableResult
    mutating func setLeftChild(of parent: VertexDescriptor, to child: VertexDescriptor) -> EdgeDescriptor?
    @discardableResult
    mutating func setRightChild(of parent: VertexDescriptor, to child: VertexDescriptor) -> EdgeDescriptor?
}

extension MutableBinaryIncidenceGraph {
    @discardableResult
    mutating func setLeftChild(of parent: VertexDescriptor, to child: VertexDescriptor) -> EdgeDescriptor? {
        if let existing = leftEdge(of: parent) { remove(edge: existing) }
        return addEdge(from: parent, to: child)
    }

    @discardableResult
    mutating func setRightChild(of parent: VertexDescriptor, to child: VertexDescriptor) -> EdgeDescriptor? {
        if let existing = rightEdge(of: parent) { remove(edge: existing) }
        return addEdge(from: parent, to: child)
    }
}
