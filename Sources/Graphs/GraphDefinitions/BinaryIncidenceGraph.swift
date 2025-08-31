protocol BinaryIncidenceGraph: Graph {
    func leftEdge(of v: VertexDescriptor) -> EdgeDescriptor?
    func rightEdge(of v: VertexDescriptor) -> EdgeDescriptor?

    func leftNeighbor(of v: VertexDescriptor) -> VertexDescriptor?
    func rightNeighbor(of v: VertexDescriptor) -> VertexDescriptor?
}
