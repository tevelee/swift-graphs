struct ReversedGraphView<Base: IncidenceGraph>: Graph {
    typealias VertexDescriptor = Base.VertexDescriptor
    typealias EdgeDescriptor = Base.EdgeDescriptor
    let base: Base
}

extension ReversedGraphView: VertexListGraph where Base: VertexListGraph {
    typealias Vertices = Base.Vertices
    func vertices() -> Vertices { base.vertices() }
    var vertexCount: Int { base.vertexCount }
}

extension ReversedGraphView: EdgeListGraph where Base: EdgeListGraph {
    typealias Edges = Base.Edges
    func edges() -> Edges { base.edges() }
    var edgeCount: Int { base.edgeCount }
}

extension ReversedGraphView: IncidenceGraph where Base: BidirectionalGraph {
    typealias OutgoingEdges = Base.IncomingEdges
    func outgoingEdges(of vertex: VertexDescriptor) -> OutgoingEdges { base.incomingEdges(of: vertex) }
    func source(of edge: EdgeDescriptor) -> VertexDescriptor? { base.destination(of: edge) }
    func destination(of edge: EdgeDescriptor) -> VertexDescriptor? { base.source(of: edge) }
    func outDegree(of vertex: VertexDescriptor) -> Int { base.inDegree(of: vertex) }
}

extension ReversedGraphView: BidirectionalGraph where Base: BidirectionalGraph {
    typealias IncomingEdges = Base.OutgoingEdges
    func incomingEdges(of vertex: VertexDescriptor) -> IncomingEdges { base.outgoingEdges(of: vertex) }
    func inDegree(of vertex: VertexDescriptor) -> Int { base.outDegree(of: vertex) }
}


