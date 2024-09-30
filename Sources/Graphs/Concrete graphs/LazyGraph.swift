/// A lazy graph structure that computes edges on demand.
public struct LazyGraph<Node, Edge> {
    /// A closure that returns the edges for a given node.
    @usableFromInline let _edges: (Node) -> [GraphEdge<Node, Edge>]

    /// Initializes a new lazy graph with a closure that provides neighbor nodes.
    /// - Parameter neighborNodes: A closure that takes a node and returns a sequence of neighbor nodes.
    @inlinable public init<Nodes: Sequence<Node>>(neighborNodes: @escaping (Node) -> Nodes) where Edge == Empty {
        _edges = { node in neighborNodes(node).lazy.map { GraphEdge(source: node, destination: $0) } }
    }

    /// Initializes a new lazy graph with a closure that provides a single neighbor node.
    /// - Parameter neighbor: A closure that takes a node and returns its single neighbor node.
    @inlinable public init(neighbor: @escaping (Node) -> Node) where Edge == Empty {
        self.init(neighborNodes: { CollectionOfOne(neighbor($0)) })
    }

    /// Initializes a new lazy graph with a custom edges closure.
    /// - Parameter edges: A closure that takes a node and returns an array of `GraphEdge` instances.
    @_disfavoredOverload
    @inlinable public init(customEdges edges: @escaping (Node) -> [GraphEdge<Node, Edge>]) {
        _edges = edges
    }

    /// Materializes the lazy graph into a concrete `Graph` starting from the specified node using the given traversal strategy.
    /// - Parameters:
    ///   - starting: The starting node for the traversal.
    ///   - strategy: The traversal strategy to use.
    ///   - isEqual: A closure that takes two nodes and returns a Boolean value indicating whether they are equal.
    /// - Returns: A concrete `Graph` instance.
    @inlinable public func materialize(starting: Node, strategy: some GraphTraversalStrategy<Node, Edge, Node>, isEqual: @escaping (Node, Node) -> Bool) -> AdjacencyListGraph<Node, Edge> {
        AdjacencyListGraph(edges: traverse(from: starting, strategy: strategy).flatMap(edges), isEqual: isEqual)
    }

    /// Materializes the lazy graph into a concrete `Graph` starting from the specified node using the given traversal strategy.
    /// - Parameters:
    ///   - starting: The starting node for the traversal.
    ///   - strategy: The traversal strategy to use.
    /// - Returns: A concrete `Graph` instance.
    @inlinable public func materialize(starting: Node, strategy: some GraphTraversalStrategy<Node, Edge, Node>) -> AdjacencyListGraph<Node, Edge> where Node: Equatable {
        AdjacencyListGraph(edges: traverse(from: starting, strategy: strategy).flatMap(edges))
    }

    /// Materializes the lazy graph into a concrete `HashedGraph` starting from the specified node using the given traversal strategy.
    /// - Parameters:
    ///   - starting: The starting node for the traversal.
    ///   - strategy: The traversal strategy to use.
    ///   - hashValue: A closure that takes a node and returns its hash value.
    /// - Returns: A concrete `HashedGraph` instance.
    @inlinable public func materialize<HashValue: Hashable>(starting: Node, strategy: some GraphTraversalStrategy<Node, Edge, Node>, hashValue: @escaping (Node) -> HashValue) -> HashedGraph<Node, Edge, HashValue> {
        HashedGraph(edges: traverse(from: starting, strategy: strategy).flatMap(edges), hashValue: hashValue)
    }

    /// Materializes the lazy graph into a concrete `HashedGraph` starting from the specified node using the given traversal strategy.
    /// - Parameters:
    ///   - starting: The starting node for the traversal.
    ///   - strategy: The traversal strategy to use.
    /// - Returns: A concrete `HashedGraph` instance.
    @inlinable public func materialize(starting: Node, strategy: some GraphTraversalStrategy<Node, Edge, Node>) -> HashedGraph<Node, Edge, Node> where Node: Hashable {
        HashedGraph(edges: traverse(from: starting, strategy: strategy).flatMap(edges))
    }
}

extension LazyGraph: ConnectedGraph {
    /// Returns the edges originating from the specified node.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: An array of `GraphEdge` instances containing the edges from the specified node.
    @inlinable public func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        _edges(node)
    }
}
