/// A protocol that extends `GraphProtocol` to include methods for accessing all nodes and edges in the graph.
public protocol Graph<Node, Edge>: GraphComponent {
    /// An array containing all nodes in the graph.
    var allNodes: [Node] { get }
    /// An array containing all edges in the graph.
    var allEdges: [GraphEdge<Node, Edge>] { get }
}

extension Graph {
    /// A default implementation that returns all edges in the graph by flattening the edges from all nodes.
    @inlinable public var allEdges: [GraphEdge<Node, Edge>] {
        allNodes.flatMap(edges)
    }
}

extension GraphComponent where Self: Graph, Node: Equatable {
    /// Returns the edges originating from the specified node.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: An array of `GraphEdge` instances containing the edges from the specified node.
    @inlinable public func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        allEdges.filter { $0.source == node }
    }
}
