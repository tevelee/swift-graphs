protocol BinaryIncidenceGraph: IncidenceGraph {
    func leftEdge(of v: VertexDescriptor) -> EdgeDescriptor?
    func rightEdge(of v: VertexDescriptor) -> EdgeDescriptor?
}

extension BinaryIncidenceGraph {
    func leftNeighbor(of v: VertexDescriptor) -> VertexDescriptor? {
        leftEdge(of: v).flatMap(destination)
    }

    func rightNeighbor(of v: VertexDescriptor) -> VertexDescriptor? {
        rightEdge(of: v).flatMap(destination)
    }
}

extension BinaryIncidenceGraph where Self: EdgeStorageBackedGraph, EdgeStore: BinaryEdgeStorage {
    func leftEdge(of v: VertexDescriptor) -> EdgeDescriptor? {
        edgeStore.leftEdge(of: v)
    }

    func rightEdge(of v: VertexDescriptor) -> EdgeDescriptor? {
        edgeStore.rightEdge(of: v)
    }
}
