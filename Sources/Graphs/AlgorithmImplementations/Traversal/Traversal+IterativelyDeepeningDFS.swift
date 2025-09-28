extension TraversalAlgorithm {
    static func iterativelyDeepeningDFS<Graph>(maxDepth: UInt? = nil) -> Self where Self == IterativelyDeepeningDFSTraversal<Graph> {
        .init(maxDepth: maxDepth)
    }
}

struct IterativelyDeepeningDFSTraversal<Graph: IncidenceGraph>: TraversalAlgorithm where Graph.VertexDescriptor: Hashable {
    typealias Visitor = DepthFirstSearch<Graph>.Visitor
    
    let maxDepth: UInt?
    
    func traverse(
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
