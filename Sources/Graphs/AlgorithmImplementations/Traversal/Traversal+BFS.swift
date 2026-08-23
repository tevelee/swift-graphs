extension TraversalAlgorithm where Graph.VertexDescriptor: Hashable {
    /// Creates a breadth-first traversal algorithm.
    ///
    /// - Returns: A BFS traversal algorithm instance.
    @inlinable
    public static func bfs<Graph>() -> Self where Self == BFSTraversal<Graph> {
        .init()
    }
}

/// A breadth-first traversal algorithm implementation for the TraversalAlgorithm protocol.
///
/// This struct wraps the core BFS algorithm to provide a TraversalAlgorithm interface,
/// making it easy to use BFS as a general traversal algorithm.
///
/// - Complexity: O(V + E) where V is the number of vertices and E is the number of edges
public struct BFSTraversal<Graph: IncidenceGraph>: TraversalAlgorithm where Graph.VertexDescriptor: Hashable {
    public typealias Event = BreadthFirstSearch<Graph>.Event

    @usableFromInline
    let shouldTraverse: ((BreadthFirstSearch<Graph>.TraversalCandidate) -> Bool)?

    /// Creates a new BFS traversal algorithm.
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

    /// Performs a breadth-first traversal from the source vertex.
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
                case .vertexExamined(let vertex): vertices.append(vertex)
                case .edgeExamined(let edge): edges.append(edge)
                default: break
            }
        }
        var iterator = BreadthFirstSearch(on: graph, from: source, shouldTraverse: shouldTraverse)
            .makeIterator(observation: collector.followed(by: observation))
        while iterator.next() != nil {}

        return TraversalResult(
            vertices: vertices,
            edges: edges
        )
    }
}

extension BFSTraversal: AlgorithmObserving {}
