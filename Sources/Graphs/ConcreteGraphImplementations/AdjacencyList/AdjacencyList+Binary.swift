extension AdjacencyList: BinaryIncidenceGraph where EdgeStore == BinaryEdgeStorage<VertexStore.Vertex> {
    func leftEdge(of v: VertexDescriptor) -> EdgeDescriptor? {
        var it = outgoingEdges(of: v).makeIterator()
        return it.next()
    }

    func rightEdge(of v: VertexDescriptor) -> EdgeDescriptor? {
        var it = outgoingEdges(of: v).makeIterator()
        _ = it.next()
        return it.next()
    }

    func leftNeighbor(of v: VertexDescriptor) -> VertexDescriptor? {
        leftEdge(of: v).flatMap(destination)
    }

    func rightNeighbor(of v: VertexDescriptor) -> VertexDescriptor? {
        rightEdge(of: v).flatMap(destination)
    }
}

extension AdjacencyList: MutableBinaryIncidenceGraph where EdgeStore == BinaryEdgeStorage<VertexStore.Vertex> {
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


