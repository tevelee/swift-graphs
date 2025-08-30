protocol AdjacencyMatrix: Graph {
    func edge(from source: VertexDescriptor, to destination: VertexDescriptor) -> EdgeDescriptor?
}
