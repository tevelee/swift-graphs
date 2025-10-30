/// A protocol for edge representations.
///
/// EdgeProtocol defines the interface for edges in a graph, providing access to
/// source and destination vertices. This protocol is used by various graph implementations
/// including lazy graphs (where edges are computed on demand) and inline graphs
/// (where edges are stored explicitly).
public protocol EdgeProtocol<Vertex> {
    associatedtype Vertex

    var source: Vertex { get }
    var destination: Vertex { get }
}

/// A simple edge implementation.
///
/// SimpleEdge provides a basic implementation of EdgeProtocol that stores
/// source and destination vertices directly.
public struct SimpleEdge<Vertex>: EdgeProtocol {
    public let source: Vertex
    public let destination: Vertex
    
    @inlinable
    public init(source: Vertex, destination: Vertex) {
        self.source = source
        self.destination = destination
    }
}

extension SimpleEdge: Equatable where Vertex: Equatable {}
extension SimpleEdge: Hashable where Vertex: Hashable {}

