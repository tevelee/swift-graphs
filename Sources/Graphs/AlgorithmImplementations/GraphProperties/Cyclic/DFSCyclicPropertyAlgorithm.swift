import Foundation

struct DFSCyclicPropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
    typealias Visitor = DepthFirstSearch<Graph>.Visitor
    
    func isCyclic(
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool {
        // Handle empty graphs and single vertex graphs
        guard graph.vertexCount > 1 else {
            return false
        }
        
        var hasCycle = false
        let cycleDetectionVisitor = DepthFirstSearch<Graph>.Visitor(
            backEdge: { edge in
                hasCycle = true
            }
        )
        
        // Run DFS from each unvisited vertex using the existing DFS implementation
        // We need to track visited vertices to handle disconnected graphs
        var visitedVertices = Set<Graph.VertexDescriptor>()
        
        for vertex in graph.vertices() {
            if !hasCycle && !visitedVertices.contains(vertex) {
                // Create a visitor that tracks visited vertices
                let trackingVisitor = DepthFirstSearch<Graph>.Visitor(
                    discoverVertex: { v in
                        visitedVertices.insert(v)
                    }
                )
                
                DepthFirstSearch(on: graph, from: vertex)
                    .withVisitor { trackingVisitor }
                    .withVisitor { cycleDetectionVisitor }
                    .withVisitor { visitor }
                    .forEach { _ in }
            }
        }
        
        return hasCycle
    }
}

extension DFSCyclicPropertyAlgorithm: VisitorSupporting {}
