extension BinaryGraph {
    /// Creates a traversal sequence from the specified node using the given traversal strategy.
    /// - Parameters:
    ///   - node: The starting node for the traversal.
    ///   - strategy: The traversal strategy to use.
    /// - Returns: A `BinaryGraphTraversal` instance representing the traversal sequence.
    @inlinable public func traversal<Visit, Strategy: BinaryGraphTraversalStrategy<Node, Edge, Visit>>(from node: Node, strategy: Strategy) -> BinaryGraphTraversal<Self, Strategy> {
        .init(graph: self, startNode: node, strategy: strategy)
    }

    /// Traverses the graph from the specified node using the given traversal strategy and returns an array of visits.
    /// - Parameters:
    ///   - node: The starting node for the traversal.
    ///   - strategy: The traversal strategy to use.
    /// - Returns: An array of visits resulting from the traversal.
    @inlinable public func traverse<Visit>(from node: Node, strategy: some BinaryGraphTraversalStrategy<Node, Edge, Visit>) -> [Visit] {
        Array(traversal(from: node, strategy: strategy))
    }
}

/// A sequence representing the traversal of a binary graph using a specified strategy.
public struct BinaryGraphTraversal<Graph: BinaryGraph, Strategy: BinaryGraphTraversalStrategy>: Sequence where Graph.Node == Strategy.Node, Graph.Edge == Strategy.Edge {
    typealias Node = Graph.Node
    typealias Edge = Graph.Edge

    /// The graph being traversed.
    public let graph: Graph
    /// The starting node for the traversal.
    public let startNode: Graph.Node
    /// The strategy used for the traversal.
    public var strategy: Strategy

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
        public let graph: Graph
        /// The storage used by the strategy during traversal.
        public var storage: Strategy.Storage
        /// The strategy used for the traversal.
        public var strategy: Strategy

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
