extension TraversalAlgorithm where Graph.VertexDescriptor: Hashable {
    /// Creates a best-first traversal algorithm.
    ///
    /// - Parameter heuristic: The heuristic function to guide the traversal.
    /// - Returns: A best-first traversal algorithm instance.
    @inlinable
    public static func bestFirst<Graph, HScore>(
        heuristic: Heuristic<Graph, HScore>
    ) -> Self where Self == BestFirstTraversal<Graph, HScore> {
        .init(heuristic: heuristic)
    }
}

/// A best-first traversal algorithm that uses a heuristic to guide exploration.
///
/// Best-first traversal explores vertices in order of their heuristic value,
/// making it useful for informed search strategies. It uses A* with uniform
/// edge weights and the provided heuristic function.
///
/// - Complexity: O(b^d) where b is the branching factor and d is the depth
public struct BestFirstTraversal<
    Graph: IncidenceGraph & EdgePropertyGraph,
    HScore: AdditiveArithmetic & Comparable
>: TraversalAlgorithm where
    Graph.VertexDescriptor: Hashable
{
    /// The visitor type for observing traversal progress.
    public typealias Visitor = AStar<Graph, Int, HScore, HScore>.Visitor
    
    /// The heuristic function used to guide the traversal.
    public let heuristic: Heuristic<Graph, HScore>
    
    /// Creates a new best-first traversal algorithm.
    ///
    /// - Parameter heuristic: The heuristic function to guide the traversal.
    @inlinable
    public init(heuristic: Heuristic<Graph, HScore>) {
        self.heuristic = heuristic
    }

    /// Performs a best-first traversal from the source vertex.
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

        AStar(
            on: graph,
            from: source,
            edgeWeight: .uniform(0),
            heuristic: heuristic,
            calculateTotalCost: { $1 }
        )
        .withVisitor {
            .init(
                examineVertex: { vertex in
                    vertices.append(vertex)
                },
                edgeRelaxed: { edge in
                    edges.append(edge)
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

extension BestFirstTraversal: VisitorSupporting {}
