protocol BidirectionalGraph: IncidenceGraph {
    associatedtype InEdges: Sequence<EdgeDescriptor>

    func inEdges(of vertex: VertexDescriptor) -> InEdges
    func inDegree(of vertex: VertexDescriptor) -> Int
    func degree(of vertex: VertexDescriptor) -> Int
}

extension BidirectionalGraph {
    func predecessors(of vertex: VertexDescriptor) -> some Sequence<VertexDescriptor> {
        inEdges(of: vertex).lazy.compactMap(source)
    }

    func degree(of vertex: VertexDescriptor) -> Int {
        inDegree(of: vertex) + outDegree(of: vertex)
    }
}
