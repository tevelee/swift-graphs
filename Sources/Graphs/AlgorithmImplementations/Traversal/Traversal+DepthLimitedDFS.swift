extension TraversalAlgorithm {
    /// Creates a depth-limited DFS traversal algorithm.
    ///
    /// - Parameter maxDepth: The maximum depth to traverse.
    /// - Returns: A depth-limited DFS traversal algorithm instance.
    @inlinable
    public static func depthLimitedDFS<Graph>(maxDepth: UInt) -> Self where Self == DepthLimitedDFSTraversal<Graph> {
        .init(maxDepth: maxDepth)
    }
}

/// A depth-limited depth-first search traversal algorithm.
///
/// This algorithm performs a depth-first search but limits the maximum depth
/// of exploration. This is useful for avoiding infinite loops in infinite
/// graphs or for implementing iterative deepening search.
///
/// - Complexity: O(b^d) where b is the branching factor and d is the max depth
public struct DepthLimitedDFSTraversal<Graph: IncidenceGraph>: TraversalAlgorithm where Graph.VertexDescriptor: Hashable {
    public typealias Event = DepthFirstSearch<Graph>.Event

    /// The maximum depth to traverse.
    public let maxDepth: UInt
    @usableFromInline
    let shouldTraverse: ((DepthFirstSearch<Graph>.TraversalCandidate) -> Bool)?

    /// Creates a new depth-limited DFS traversal algorithm.
    ///
    /// - Parameter maxDepth: The maximum depth to traverse.
    @inlinable
    public init(maxDepth: UInt) {
        self.maxDepth = maxDepth
        self.shouldTraverse = nil
    }

    @inlinable
    init(maxDepth: UInt, shouldTraverse: ((DepthFirstSearch<Graph>.TraversalCandidate) -> Bool)?) {
        self.maxDepth = maxDepth
        self.shouldTraverse = shouldTraverse
    }

    /// Adds a policy that decides whether candidate tree edges may be traversed.
    @inlinable
    public func allowingTraversal(_ predicate: @escaping (DepthFirstSearch<Graph>.TraversalCandidate) -> Bool) -> Self {
        let earlier = shouldTraverse
        return .init(maxDepth: maxDepth) { candidate in
            (earlier?(candidate) ?? true) && predicate(candidate)
        }
    }
    /// Performs a depth-limited DFS traversal from the source vertex.
    ///
    /// - Parameters:
    ///   - source: The vertex to start traversal from.
    ///   - graph: The graph to traverse.
    ///   - observation: An optional observation of the traversal progress.
    /// - Returns: The traversal result containing vertices and edges.
    @inlinable
    public func traverse(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> TraversalResult<Graph.VertexDescriptor, Graph.EdgeDescriptor> {
        var vertices: [Graph.VertexDescriptor] = []
        var edges: [Graph.EdgeDescriptor] = []
        let collector = AlgorithmObservation<Event> { event in
            switch event {
                case .vertexDiscovered(let vertex): vertices.append(vertex)
                case .treeEdgeTraversed(let edge): edges.append(edge)
                default: break
            }
        }
        let callerPolicy = shouldTraverse
        let policy: (DepthFirstSearch<Graph>.TraversalCandidate) -> Bool = { candidate in
            let withinDepth = (candidate.context.depth(of: candidate.from) ?? 0) < maxDepth
            return withinDepth && (callerPolicy?(candidate) ?? true)
        }
        var iterator = DepthFirstSearch(on: graph, from: source, shouldTraverse: policy)
            .makeIterator(observation: collector.followed(by: observation))
        while iterator.next() != nil {}
        return TraversalResult(vertices: vertices, edges: edges)
    }
}

extension DepthLimitedDFSTraversal: AlgorithmObserving {}
