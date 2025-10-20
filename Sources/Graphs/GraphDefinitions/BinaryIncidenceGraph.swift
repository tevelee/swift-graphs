/// A protocol for graphs that represent binary trees.
///
/// Binary incidence graphs extend the incidence graph concept to specifically support
/// binary tree structures where each vertex has at most two children (left and right).
/// This is useful for algorithms that work specifically with binary trees.
public protocol BinaryIncidenceGraph: IncidenceGraph {
    /// Returns the left edge from the specified vertex.
    ///
    /// - Parameter v: The vertex to query
    /// - Returns: The left edge descriptor, or `nil` if no left edge exists
    @inlinable
    func leftEdge(of v: VertexDescriptor) -> EdgeDescriptor?
    
    /// Returns the right edge from the specified vertex.
    ///
    /// - Parameter v: The vertex to query
    /// - Returns: The right edge descriptor, or `nil` if no right edge exists
    @inlinable
    func rightEdge(of v: VertexDescriptor) -> EdgeDescriptor?
}

extension BinaryIncidenceGraph {
    @inlinable
    public func leftNeighbor(of v: VertexDescriptor) -> VertexDescriptor? {
        leftEdge(of: v).flatMap(destination)
    }

    @inlinable
    public func rightNeighbor(of v: VertexDescriptor) -> VertexDescriptor? {
        rightEdge(of: v).flatMap(destination)
    }
}

extension BinaryIncidenceGraph where Self: EdgeStorageBackedGraph, EdgeStore: BinaryEdgeStorage {
    @inlinable
    public func leftEdge(of v: VertexDescriptor) -> EdgeDescriptor? {
        edgeStore.leftEdge(of: v)
    }

    @inlinable
    public func rightEdge(of v: VertexDescriptor) -> EdgeDescriptor? {
        edgeStore.rightEdge(of: v)
    }
}
