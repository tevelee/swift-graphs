/// A protocol for mutable graphs that represent binary trees.
///
/// Mutable binary incidence graphs extend binary incidence graphs with the ability
/// to modify the tree structure by setting left and right neighbors of vertices.
/// This is useful for building and modifying binary tree structures.
public protocol MutableBinaryIncidenceGraph: BinaryIncidenceGraph, MutableGraph {
    /// Sets the left neighbor of a parent vertex to a child vertex.
    ///
    /// - Parameters:
    ///   - parent: The parent vertex
    ///   - child: The child vertex to set as the left neighbor
    /// - Returns: The edge descriptor of the created edge, or `nil` if the operation failed
    @discardableResult
    @inlinable
    mutating func setLeftNeighbor(of parent: VertexDescriptor, to child: VertexDescriptor) -> EdgeDescriptor?
    
    /// Sets the right neighbor of a parent vertex to a child vertex.
    ///
    /// - Parameters:
    ///   - parent: The parent vertex
    ///   - child: The child vertex to set as the right neighbor
    /// - Returns: The edge descriptor of the created edge, or `nil` if the operation failed
    @discardableResult
    @inlinable
    mutating func setRightNeighbor(of parent: VertexDescriptor, to child: VertexDescriptor) -> EdgeDescriptor?
}

extension MutableBinaryIncidenceGraph {
    @discardableResult
    @inlinable
    public mutating func setLeftNeighbor(of parent: VertexDescriptor, to child: VertexDescriptor) -> EdgeDescriptor? {
        if let existing = leftEdge(of: parent) { remove(edge: existing) }
        return addEdge(from: parent, to: child)
    }

    @discardableResult
    @inlinable
    public mutating func setRightNeighbor(of parent: VertexDescriptor, to child: VertexDescriptor) -> EdgeDescriptor? {
        if let existing = rightEdge(of: parent) { remove(edge: existing) }
        return addEdge(from: parent, to: child)
    }
}
