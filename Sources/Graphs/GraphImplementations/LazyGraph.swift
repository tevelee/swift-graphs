/// A protocol for lazy edge representations.
///
/// LazyEdge defines the interface for edges that are computed on demand,
/// allowing for efficient representation of graphs where edges are not
/// explicitly stored but can be computed when needed.
public protocol LazyEdge<Vertex> {
    associatedtype Vertex

    var source: Vertex { get }
    var destination: Vertex { get }
}

/// A simple edge implementation for lazy graphs.
///
/// SimpleEdge provides a basic implementation of LazyEdge that stores
/// source and destination vertices directly.
public struct SimpleEdge<Vertex>: LazyEdge {
    public let source: Vertex
    public let destination: Vertex
    
    @inlinable
    public init(source: Vertex, destination: Vertex) {
        self.source = source
        self.destination = destination
    }
}

/// A lazy incidence graph that computes edges on demand.
///
/// LazyIncidenceGraph provides an efficient way to represent graphs where
/// edges are computed dynamically rather than stored explicitly. This is
/// useful for large graphs or graphs with regular structure.
public struct LazyIncidenceGraph<Vertex, Edge: LazyEdge<Vertex>, Edges: Collection<Edge>> {
    public let edgeProvider: (VertexDescriptor) -> Edges
    
    @inlinable
    public init(edges: @escaping (VertexDescriptor) -> Edges) {
        self.edgeProvider = edges
    }
}

extension LazyIncidenceGraph: Graph {
    public typealias VertexDescriptor = Vertex
    public typealias EdgeDescriptor = Edge
}

extension LazyIncidenceGraph: IncidenceGraph {
    @inlinable
    public func outgoingEdges(of vertex: Vertex) -> Edges {
        edgeProvider(vertex)
    }
    
    @inlinable
    public func source(of edge: Edge) -> Vertex? {
        edge.source
    }
    
    @inlinable
    public func destination(of edge: Edge) -> Vertex? {
        edge.destination
    }
    
    @inlinable
    public func outDegree(of vertex: Vertex) -> Int {
        edgeProvider(vertex).count
    }
}

extension LazyIncidenceGraph {
    @inlinable
    public init<Neighbors: Collection<Vertex>>(neighbors: @escaping (VertexDescriptor) -> Neighbors) where Edges == LazyMapCollection<Neighbors, SimpleEdge<Vertex>> {
        self.edgeProvider = { source in
            neighbors(source).lazy.map {
                SimpleEdge(source: source, destination: $0)
            }
        }
    }
}
