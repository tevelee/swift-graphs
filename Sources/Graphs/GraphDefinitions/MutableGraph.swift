protocol MutableGraph: Graph {
    @discardableResult
    mutating func addEdge(from source: VertexDescriptor, to destination: VertexDescriptor) -> EdgeDescriptor?
    mutating func remove(edge: consuming EdgeDescriptor)

    mutating func addVertex() -> VertexDescriptor
    mutating func remove(vertex: consuming VertexDescriptor)
}
