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
    /// The visitor type for observing traversal progress.
    public typealias Visitor = BreadthFirstSearch<Graph>.Visitor
    
    /// Creates a new BFS traversal algorithm.
    @inlinable
    public init() {}
    
    /// Performs a breadth-first traversal from the source vertex.
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

        BreadthFirstSearch(on: graph, from: source)
            .withVisitor {
                .init(
                    examineVertex: { vertex in
                        vertices.append(vertex)
                    },
                    examineEdge: { edge in
                        edges.append(edge)
                    }
                )
            }
            .withVisitor {
                visitor
            }
            .forEach { _ in }
        
        return TraversalResult(
            vertices: vertices,
            edges: edges
        )
    }
}

extension BFSTraversal: VisitorSupporting {}
