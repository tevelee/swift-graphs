extension SearchAlgorithm {
    /// Creates a breadth-first search algorithm.
    ///
    /// - Returns: A BFS search algorithm instance.
    @inlinable
    public static func bfs<Graph>() -> Self where Self == BFSSearch<Graph> {
        .init()
    }
}

/// A breadth-first search algorithm implementation for the SearchAlgorithm protocol.
///
/// This struct wraps the core BFS algorithm to provide a SearchAlgorithm interface,
/// making it easy to use BFS as a general search algorithm.
///
/// - Complexity: O(V + E) where V is the number of vertices and E is the number of edges
public struct BFSSearch<Graph: IncidenceGraph>: SearchAlgorithm where Graph.VertexDescriptor: Hashable {
    public typealias Event = BreadthFirstSearch<Graph>.Event

    @usableFromInline
    let shouldTraverse: ((BreadthFirstSearch<Graph>.TraversalCandidate) -> Bool)?

    /// Creates a new BFS search algorithm.
    @inlinable
    public init() {
        self.shouldTraverse = nil
    }

    @inlinable
    init(shouldTraverse: ((BreadthFirstSearch<Graph>.TraversalCandidate) -> Bool)?) {
        self.shouldTraverse = shouldTraverse
    }

    /// Adds a policy that decides whether candidate tree edges may be traversed.
    @inlinable
    public func allowingTraversal(
        _ predicate: @escaping (BreadthFirstSearch<Graph>.TraversalCandidate) -> Bool
    ) -> Self {
        let earlier = shouldTraverse
        return .init { candidate in
            (earlier?(candidate) ?? true) && predicate(candidate)
        }
    }

    /// Performs a breadth-first search from the source vertex.
    ///
    /// - Parameters:
    ///   - source: The vertex to start search from.
    ///   - graph: The graph to search in.
    ///   - observation: An optional observation of the search progress.
    /// - Returns: A BFS algorithm instance.
    @inlinable
    public func search(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> BreadthFirstSearch<Graph> {
        BreadthFirstSearch(
            on: graph,
            from: source,
            observation: observation,
            shouldTraverse: shouldTraverse
        )
    }
}

extension BFSSearch: AlgorithmObserving {}
