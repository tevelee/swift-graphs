/// A protocol for graphs that use edge storage for their edge management.
///
/// This protocol allows graphs to delegate edge management to a separate
/// storage component, enabling different storage strategies and implementations.
public protocol EdgeStorageBackedGraph: Graph {
    /// The type of edge storage used by this graph.
    associatedtype EdgeStore: EdgeStorage where EdgeStore.Vertex == VertexDescriptor, EdgeStore.Edge == EdgeDescriptor
    
    /// The edge storage component.
    var edgeStore: EdgeStore { get set }
}

extension EdgeListGraph where Self: EdgeStorageBackedGraph {
    @inlinable
    public func edges() -> EdgeStore.Edges { edgeStore.edges() }
    
    @inlinable
    public var edgeCount: Int { edgeStore.edgeCount }
}

extension IncidenceGraph where Self: EdgeStorageBackedGraph, OutgoingEdges == EdgeStore.Edges {
    @inlinable
    public func outgoingEdges(of vertex: VertexDescriptor) -> OutgoingEdges { edgeStore.outgoingEdges(of: vertex) }
    
    @inlinable
    public func source(of edge: EdgeDescriptor) -> VertexDescriptor? { edgeStore.endpoints(of: edge)?.source }
    
    @inlinable
    public func destination(of edge: EdgeDescriptor) -> VertexDescriptor? { edgeStore.endpoints(of: edge)?.destination }
    
    @inlinable
    public func outDegree(of vertex: VertexDescriptor) -> Int { edgeStore.outDegree(of: vertex) }
}

// Defaults for bidirectional incidence via the backing store
extension BidirectionalGraph where Self: EdgeStorageBackedGraph, IncomingEdges == EdgeStore.Edges {
    @inlinable
    public func incomingEdges(of vertex: VertexDescriptor) -> IncomingEdges { edgeStore.incomingEdges(of: vertex) }
    
    @inlinable
    public func inDegree(of vertex: VertexDescriptor) -> Int { edgeStore.inDegree(of: vertex) }
}


