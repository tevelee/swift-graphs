protocol BinaryIncidenceGraph: Graph {
    func leftEdge(of v: VertexDescriptor) -> EdgeDescriptor?
    func rightEdge(of v: VertexDescriptor) -> EdgeDescriptor?

    func leftChild(of v: VertexDescriptor) -> VertexDescriptor?
    func rightChild(of v: VertexDescriptor) -> VertexDescriptor?
}
