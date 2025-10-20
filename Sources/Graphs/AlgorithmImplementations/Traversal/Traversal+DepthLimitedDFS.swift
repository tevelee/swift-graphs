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
    /// The visitor type for observing traversal progress.
    public typealias Visitor = DepthFirstSearch<Graph>.Visitor
    
    /// The maximum depth to traverse.
    public let maxDepth: UInt
    
    /// Creates a new depth-limited DFS traversal algorithm.
    ///
    /// - Parameter maxDepth: The maximum depth to traverse.
    @inlinable
    public init(maxDepth: UInt) {
        self.maxDepth = maxDepth
    }
    /// Performs a depth-limited DFS traversal from the source vertex.
    ///
    /// - Parameters:
    ///   - source: The vertex to start traversal from.
    ///   - graph: The graph to traverse.
    ///   - visitor: An optional visitor to observe the traversal progress.
    /// - Returns: The traversal result containing vertices and edges.
    @inlinable
    public func traverse(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> TraversalResult<Graph.VertexDescriptor, Graph.EdgeDescriptor> {
        var vertices: [Graph.VertexDescriptor] = []
        var edges: [Graph.EdgeDescriptor] = []
        DepthFirstSearch(on: graph, from: source)
            .withVisitor {
                .init(
                    discoverVertex: { v in vertices.append(v) },
                    treeEdge: { e in edges.append(e) },
                    shouldTraverse: { args in
                        guard let depth = args.context.depth(of: args.from) else { return true }
                        return depth < maxDepth
                    }
                )
            }
            .withVisitor {
                visitor
            }
            .forEach { _ in }
        return TraversalResult(vertices: vertices, edges: edges)
    }
}

extension DepthLimitedDFSTraversal: VisitorSupporting {}
