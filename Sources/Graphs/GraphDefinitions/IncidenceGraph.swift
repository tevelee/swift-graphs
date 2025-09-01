protocol IncidenceGraph<VertexDescriptor, EdgeDescriptor>: Graph {
    associatedtype OutEdges: Sequence<EdgeDescriptor>

    func outEdges(of vertex: VertexDescriptor) -> OutEdges
    func source(of edge: EdgeDescriptor) -> VertexDescriptor?
    func destination(of edge: EdgeDescriptor) -> VertexDescriptor?
    func outDegree(of vertex: VertexDescriptor) -> Int
}

extension IncidenceGraph {
    func successors(of vertex: VertexDescriptor) -> some Sequence<VertexDescriptor> {
        outEdges(of: vertex).lazy.compactMap(destination)
    }
}
