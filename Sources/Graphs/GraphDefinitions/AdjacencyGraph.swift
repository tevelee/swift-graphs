import Collections

/// A protocol for graphs that provide direct access to adjacent vertices.
///
/// Adjacency graphs allow efficient access to all vertices that are directly
/// connected to a given vertex, without needing to traverse through edges.
/// This is useful for algorithms that need to work with vertex neighborhoods.
public protocol AdjacencyGraph: Graph {
    associatedtype AdjacentVertices: Sequence<VertexDescriptor>

    /// Returns all vertices adjacent to the specified vertex.
    ///
    /// - Parameter vertex: The vertex to query
    /// - Returns: A sequence of adjacent vertex descriptors
    func adjacentVertices(of vertex: VertexDescriptor) -> AdjacentVertices
}

extension AdjacencyGraph where Self: BidirectionalGraph, VertexDescriptor: Hashable {
    @inlinable
    public func adjacentVertices(of vertex: VertexDescriptor) -> OrderedSet<VertexDescriptor> {
        var result: OrderedSet<VertexDescriptor> = []
        result.append(contentsOf: outgoingEdges(of: vertex).compactMap(destination))
        result.append(contentsOf: incomingEdges(of: vertex).compactMap(source))
        return result
    }
}
