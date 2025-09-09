protocol IncidenceGraph<VertexDescriptor, EdgeDescriptor>: Graph {
    associatedtype OutgoingEdges: Sequence<EdgeDescriptor>

    func outgoingEdges(of vertex: VertexDescriptor) -> OutgoingEdges
    func source(of edge: EdgeDescriptor) -> VertexDescriptor?
    func destination(of edge: EdgeDescriptor) -> VertexDescriptor?
    func outDegree(of vertex: VertexDescriptor) -> Int
}

extension IncidenceGraph {
    func successors(of vertex: VertexDescriptor) -> some Sequence<VertexDescriptor> {
        outgoingEdges(of: vertex).lazy.compactMap(destination)
    }

    func isSink(vertex: VertexDescriptor) -> Bool {
        outDegree(of: vertex) == 0
    }
}
