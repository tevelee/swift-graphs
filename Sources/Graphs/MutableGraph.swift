/// A protocol that represents a mutable graph component.
public protocol MutableGraphComponent<Node, Edge>: GraphComponent {
    /// Adds an edge to the graph.
    /// - Parameter edge: The edge to add.
    mutating func addEdge(_ edge: GraphEdge<Node, Edge>)
    /// Removes an edge from the graph.
    /// - Parameter condition: A closure that determines if an edge should be removed.
    mutating func removeEdge(where condition: (GraphEdge<Node, Edge>) -> Bool)
}

/// A protocol that represents a mutable graph.
public protocol MutableGraph<Node, Edge>: MutableGraphComponent, Graph {
    /// Adds a node to the graph.
    /// - Parameter node: The node to add.
    mutating func addNode(_ node: Node)
    /// Removes a node from the graph.
    /// - Parameter condition: A closure that determines if a node should be removed.
    mutating func removeNode(where condition: (Node) -> Bool)
}
