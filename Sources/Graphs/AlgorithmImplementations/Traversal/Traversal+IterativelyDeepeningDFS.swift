extension TraversalAlgorithm {
    /// Creates an iteratively deepening DFS traversal algorithm.
    ///
    /// - Parameter maxDepth: The maximum depth to traverse, or nil for unlimited.
    /// - Returns: An iteratively deepening DFS traversal algorithm instance.
    @inlinable
    public static func iterativelyDeepeningDFS<Graph>(maxDepth: UInt? = nil) -> Self where Self == IterativelyDeepeningDFSTraversal<Graph> {
        .init(maxDepth: maxDepth)
    }
}

/// An iteratively deepening depth-first search traversal algorithm.
///
/// This algorithm performs multiple depth-first searches with increasing depth
/// limits, starting from depth 0. This combines the space efficiency of DFS
/// with the completeness of breadth-first search, making it useful for
/// uninformed search in infinite or very large graphs.
///
/// - Complexity: O(b^d) where b is the branching factor and d is the depth
public struct IterativelyDeepeningDFSTraversal<Graph: IncidenceGraph>: TraversalAlgorithm where Graph.VertexDescriptor: Hashable {
    public typealias Event = DepthFirstSearch<Graph>.Event

    /// The maximum depth to traverse, or nil for unlimited.
    public let maxDepth: UInt?
    @usableFromInline
    let shouldTraverse: ((DepthFirstSearch<Graph>.TraversalCandidate) -> Bool)?

    /// Creates a new iteratively deepening DFS traversal algorithm.
    ///
    /// - Parameter maxDepth: The maximum depth to traverse, or nil for unlimited.
    @inlinable
    public init(maxDepth: UInt? = nil) {
        self.maxDepth = maxDepth
        self.shouldTraverse = nil
    }

    @inlinable
    init(maxDepth: UInt?, shouldTraverse: ((DepthFirstSearch<Graph>.TraversalCandidate) -> Bool)?) {
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

    /// Performs an iteratively deepening DFS traversal from the source vertex.
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
        var allVertices: [Graph.VertexDescriptor] = []
        var allEdges: [Graph.EdgeDescriptor] = []
        var visitedVertices = Set<Graph.VertexDescriptor>()
        var observedVertices = Set<Graph.VertexDescriptor>()

        // Perform IDDFS by increasing depth limit
        var depth = 0
        while true {
            // Check if we've exceeded the maximum depth
            if let maxDepth = maxDepth, depth > maxDepth {
                break
            }

            var depthVertices: [Graph.VertexDescriptor] = []
            var depthEdges: [Graph.EdgeDescriptor] = []

            let depthObservation = AlgorithmObservation<Event> { event in
                switch event {
                    case .vertexDiscovered(let vertex):
                        if !visitedVertices.contains(vertex) {
                            depthVertices.append(vertex)
                        }
                        if observedVertices.insert(vertex).inserted {
                            observation?.receive(event)
                        }
                    case .treeEdgeTraversed(let edge):
                        depthEdges.append(edge)
                        observation?.receive(event)
                    default:
                        observation?.receive(event)
                }
            }
            let callerPolicy = shouldTraverse
            let depthPolicy: (DepthFirstSearch<Graph>.TraversalCandidate) -> Bool = { candidate in
                let currentDepth = candidate.context.depth(of: candidate.from) ?? 0
                return currentDepth < depth && (callerPolicy?(candidate) ?? true)
            }

            // Perform DFS with current depth limit
            var iterator = DepthFirstSearch(on: graph, from: source, shouldTraverse: depthPolicy)
                .makeIterator(observation: depthObservation)
            while iterator.next() != nil {}

            // Add newly discovered vertices to the result
            for vertex in depthVertices where visitedVertices.insert(vertex).inserted {
                allVertices.append(vertex)
            }
            allEdges.append(contentsOf: depthEdges)

            // If we didn't discover any new vertices at this depth, we've explored everything
            if depthVertices.isEmpty {
                break
            }

            depth += 1
        }

        return TraversalResult(vertices: allVertices, edges: allEdges)
    }

}

extension IterativelyDeepeningDFSTraversal: AlgorithmObserving {}
