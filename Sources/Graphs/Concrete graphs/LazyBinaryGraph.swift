/// A lazy binary graph structure that computes edges on demand.
public struct LazyBinaryGraph<Node, Edge> {
    /// A closure that returns the edges for a given node.
    @usableFromInline let _edges: (Node) -> BinaryGraphEdges<Node, Edge>

    /// Initializes a new lazy binary graph with a closure that provides neighbor nodes.
    /// - Parameter neighborNodes: A closure that takes a node and returns an optional tuple containing the left-hand side and right-hand side neighbor nodes.
    @inlinable public init(neighborNodes: @escaping (Node) -> (lhs: Node?, rhs: Node?)?) where Edge == Void {
        _edges = { node in
            let destinations = neighborNodes(node)
            return BinaryGraphEdges(
                source: node,
                lhs: destinations?.lhs.map { .init(source: node, destination: $0) },
                rhs: destinations?.rhs.map { .init(source: node, destination: $0) }
            )
        }
    }

    /// Initializes a new lazy binary graph with a custom edges closure.
    /// - Parameter edges: A closure that takes a node and returns its `BinaryGraphEdges`.
    @_disfavoredOverload
    @inlinable public init(customEdges edges: @escaping (Node) -> BinaryGraphEdges<Node, Edge>) {
        _edges = edges
    }
}

extension LazyBinaryGraph: BinaryGraph {
    /// Returns the edges originating from the specified node.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: A `BinaryGraphEdges` instance containing the edges from the specified node.
    @inlinable public func edges(from node: Node) -> BinaryGraphEdges<Node, Edge> {
        _edges(node)
    }
}
