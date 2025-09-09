protocol EdgeStorageBackedGraph: Graph {
    associatedtype EdgeStore: EdgeStorage where EdgeStore.Vertex == VertexDescriptor, EdgeStore.Edge == EdgeDescriptor
    var edgeStore: EdgeStore { get set }
}

extension EdgeListGraph where Self: EdgeStorageBackedGraph {
    func edges() -> EdgeStore.Edges { edgeStore.edges() }
    var edgeCount: Int { edgeStore.edgeCount }
}

extension IncidenceGraph where Self: EdgeStorageBackedGraph, OutgoingEdges == EdgeStore.Edges {
    func outgoingEdges(of vertex: VertexDescriptor) -> OutgoingEdges { edgeStore.outgoingEdges(of: vertex) }
    func source(of edge: EdgeDescriptor) -> VertexDescriptor? { edgeStore.endpoints(of: edge)?.source }
    func destination(of edge: EdgeDescriptor) -> VertexDescriptor? { edgeStore.endpoints(of: edge)?.destination }
    func outDegree(of vertex: VertexDescriptor) -> Int { edgeStore.outDegree(of: vertex) }
}

// Defaults for bidirectional incidence via the backing store
extension BidirectionalGraph where Self: EdgeStorageBackedGraph, IncomingEdges == EdgeStore.Edges {
    func incomingEdges(of vertex: VertexDescriptor) -> IncomingEdges { edgeStore.incomingEdges(of: vertex) }
    func inDegree(of vertex: VertexDescriptor) -> Int { edgeStore.inDegree(of: vertex) }
}


