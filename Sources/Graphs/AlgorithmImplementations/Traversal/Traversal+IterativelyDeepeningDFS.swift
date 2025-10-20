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
    /// The visitor type for observing traversal progress.
    public typealias Visitor = DepthFirstSearch<Graph>.Visitor
    
    /// The maximum depth to traverse, or nil for unlimited.
    public let maxDepth: UInt?
    
    /// Creates a new iteratively deepening DFS traversal algorithm.
    ///
    /// - Parameter maxDepth: The maximum depth to traverse, or nil for unlimited.
    @inlinable
    public init(maxDepth: UInt? = nil) {
        self.maxDepth = maxDepth
    }
    
    /// Performs an iteratively deepening DFS traversal from the source vertex.
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
        var allVertices: [Graph.VertexDescriptor] = []
        var allEdges: [Graph.EdgeDescriptor] = []
        var visitedVertices = Set<Graph.VertexDescriptor>()
        var visitorCalledVertices = Set<Graph.VertexDescriptor>()
        
        // Perform IDDFS by increasing depth limit
        var depth = 0
        while true {
            // Check if we've exceeded the maximum depth
            if let maxDepth = maxDepth, depth > maxDepth {
                break
            }
            
            var depthVertices: [Graph.VertexDescriptor] = []
            var depthEdges: [Graph.EdgeDescriptor] = []
            
            // Create a visitor that collects vertices and edges for this depth
            let depthVisitor = DepthFirstSearch<Graph>.Visitor(
                discoverVertex: { vertex in
                    if !visitedVertices.contains(vertex) {
                        depthVertices.append(vertex)
                    }
                    // Only call visitor once per vertex
                    if !visitorCalledVertices.contains(vertex) {
                        visitorCalledVertices.insert(vertex)
                        visitor?.discoverVertex?(vertex)
                    }
                },
                examineVertex: { vertex in
                    visitor?.examineVertex?(vertex)
                },
                examineEdge: { edge in
                    visitor?.examineEdge?(edge)
                },
                treeEdge: { edge in
                    depthEdges.append(edge)
                    visitor?.treeEdge?(edge)
                },
                backEdge: { edge in
                    visitor?.backEdge?(edge)
                },
                forwardEdge: { edge in
                    visitor?.forwardEdge?(edge)
                },
                crossEdge: { edge in
                    visitor?.crossEdge?(edge)
                },
                finishVertex: { vertex in
                    visitor?.finishVertex?(vertex)
                },
                shouldTraverse: { args in
                    guard let currentDepth = args.context.depth(of: args.from) else { return true }
                    let shouldTraverse = currentDepth < depth
                    let visitorShouldTraverse = visitor?.shouldTraverse?(args) ?? true
                    return shouldTraverse && visitorShouldTraverse
                }
            )
            
            // Perform DFS with current depth limit
            DepthFirstSearch(on: graph, from: source)
                .withVisitor { depthVisitor }
                .forEach { _ in }
            
            // Add newly discovered vertices to the result
            for vertex in depthVertices {
                if visitedVertices.insert(vertex).inserted {
                    allVertices.append(vertex)
                }
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

extension IterativelyDeepeningDFSTraversal: VisitorSupporting {}
