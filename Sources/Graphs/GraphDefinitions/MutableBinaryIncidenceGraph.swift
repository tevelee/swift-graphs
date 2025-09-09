protocol MutableBinaryIncidenceGraph: BinaryIncidenceGraph, MutableGraph {
    @discardableResult
    mutating func setLeftNeighbor(of parent: VertexDescriptor, to child: VertexDescriptor) -> EdgeDescriptor?
    @discardableResult
    mutating func setRightNeighbor(of parent: VertexDescriptor, to child: VertexDescriptor) -> EdgeDescriptor?
}

extension MutableBinaryIncidenceGraph {
    @discardableResult
    mutating func setLeftNeighbor(of parent: VertexDescriptor, to child: VertexDescriptor) -> EdgeDescriptor? {
        if let existing = leftEdge(of: parent) { remove(edge: existing) }
        return addEdge(from: parent, to: child)
    }

    @discardableResult
    mutating func setRightNeighbor(of parent: VertexDescriptor, to child: VertexDescriptor) -> EdgeDescriptor? {
        if let existing = rightEdge(of: parent) { remove(edge: existing) }
        return addEdge(from: parent, to: child)
    }
}
