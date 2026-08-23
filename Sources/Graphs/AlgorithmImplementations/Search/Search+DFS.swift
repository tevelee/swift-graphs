extension SearchAlgorithm {
    /// Creates a depth-first search algorithm.
    ///
    /// - Returns: A DFS search algorithm instance.
    @inlinable
    public static func dfs<Graph>() -> Self where Self == DFSSearch<Graph> {
        .init()
    }
}

/// A depth-first search algorithm implementation for the SearchAlgorithm protocol.
///
/// This struct wraps the core DFS algorithm to provide a SearchAlgorithm interface,
/// making it easy to use DFS as a general search algorithm.
///
/// - Complexity: O(V + E) where V is the number of vertices and E is the number of edges
public struct DFSSearch<Graph: IncidenceGraph>: SearchAlgorithm where Graph.VertexDescriptor: Hashable {
    public typealias Event = DepthFirstSearch<Graph>.Event

    @usableFromInline
    let shouldTraverse: ((DepthFirstSearch<Graph>.TraversalCandidate) -> Bool)?

    /// Creates a new DFS search algorithm.
    @inlinable
    public init() {
        self.shouldTraverse = nil
    }

    @inlinable
    init(shouldTraverse: ((DepthFirstSearch<Graph>.TraversalCandidate) -> Bool)?) {
        self.shouldTraverse = shouldTraverse
    }

    /// Adds a policy that decides whether candidate tree edges may be traversed.
    @inlinable
    public func allowingTraversal(
        _ predicate: @escaping (DepthFirstSearch<Graph>.TraversalCandidate) -> Bool
    ) -> Self {
        let earlier = shouldTraverse
        return .init { candidate in
            (earlier?(candidate) ?? true) && predicate(candidate)
        }
    }

    /// Performs a depth-first search from the source vertex.
    ///
    /// - Parameters:
    ///   - source: The vertex to start search from.
    ///   - graph: The graph to search in.
    ///   - observation: An optional observation of the search progress.
    /// - Returns: A DFS algorithm instance.
    @inlinable
    public func search(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> DepthFirstSearch<Graph> {
        DepthFirstSearch(
            on: graph,
            from: source,
            observation: observation,
            shouldTraverse: shouldTraverse
        )
    }
}

extension DFSSearch: AlgorithmObserving {}
