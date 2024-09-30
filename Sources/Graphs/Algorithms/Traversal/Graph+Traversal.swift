extension ConnectedGraph {
    /// Creates a traversal sequence from the specified node using the given traversal strategy.
    /// - Parameters:
    ///   - node: The starting node for the traversal.
    ///   - strategy: The traversal strategy to use.
    /// - Returns: A `GraphTraversal` instance representing the traversal sequence.
    @inlinable public func traversal<Visit, Strategy: GraphTraversalStrategy<Node, Edge, Visit>>(from node: Node, strategy: Strategy) -> GraphTraversal<Self, Strategy> {
        .init(graph: self, startNode: node, strategy: strategy)
    }

    /// Traverses the graph from the specified node using the given traversal strategy and returns an array of visits.
    /// - Parameters:
    ///   - node: The starting node for the traversal.
    ///   - strategy: The traversal strategy to use.
    /// - Returns: An array of visits resulting from the traversal.
    @inlinable public func traverse<Visit>(from node: Node, strategy: some GraphTraversalStrategy<Node, Edge, Visit>) -> [Visit] {
        Array(traversal(from: node, strategy: strategy))
    }
}

/// A sequence representing the traversal of a graph using a specified strategy.
public struct GraphTraversal<Graph: ConnectedGraph, Strategy: GraphTraversalStrategy>: Sequence where Graph.Node == Strategy.Node, Graph.Edge == Strategy.Edge {
    typealias Node = Graph.Node
    typealias Edge = Graph.Edge

    /// The graph being traversed.
    @usableFromInline let graph: Graph
    /// The starting node for the traversal.
    @usableFromInline let startNode: Graph.Node
    /// The strategy used for the traversal.
    @usableFromInline var strategy: Strategy

    /// Initializes a new traversal sequence.
    /// - Parameters:
    ///   - graph: The graph to traverse.
    ///   - startNode: The starting node for the traversal.
    ///   - strategy: The strategy to use for the traversal.
    @inlinable public init(graph: Graph, startNode: Graph.Node, strategy: Strategy) {
        self.graph = graph
        self.startNode = startNode
        self.strategy = strategy
    }

    /// An iterator for the traversal sequence.
    public struct Iterator: IteratorProtocol {
        /// The graph being traversed.
        @usableFromInline let graph: Graph
        /// The storage used by the strategy during traversal.
        @usableFromInline var storage: Strategy.Storage
        /// The strategy used for the traversal.
        @usableFromInline var strategy: Strategy

        /// Initializes a new iterator for the traversal sequence.
        /// - Parameters:
        ///   - graph: The graph to traverse.
        ///   - startNode: The starting node for the traversal.
        ///   - strategy: The strategy to use for the traversal.
        @inlinable public init(graph: Graph, startNode: Graph.Node, strategy: Strategy) {
            self.graph = graph
            self.strategy = strategy
            self.storage = strategy.initializeStorage(startNode: startNode)
        }

        /// Advances to the next element in the traversal sequence.
        /// - Returns: The next visit in the traversal sequence, or `nil` if there are no more visits.
        @inlinable public mutating func next() -> Strategy.Visit? {
            strategy.next(from: &storage, graph: graph)
        }
    }

    /// Creates an iterator for the traversal sequence.
    /// - Returns: An iterator for the traversal sequence.
    @inlinable public func makeIterator() -> Iterator {
        Iterator(graph: graph, startNode: startNode, strategy: strategy)
    }
}
