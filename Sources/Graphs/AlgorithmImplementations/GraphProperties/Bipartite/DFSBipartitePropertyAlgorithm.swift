import Foundation

struct DFSBipartitePropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
    typealias Visitor = DFSBipartiteProperty<Graph>.Visitor
    
    func isBipartite(
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool {
        // Handle empty graphs and single vertex graphs
        guard graph.vertexCount > 0 else {
            return true // Empty graph is considered bipartite
        }
        
        guard graph.vertexCount > 1 else {
            return true // Single vertex graph is bipartite
        }
        
        // Color map: 0 = uncolored, 1 = color A, 2 = color B
        var color = [Graph.VertexDescriptor: Int]()
        var isBipartite = true
        
        // Process each connected component using DFS
        for vertex in graph.vertices() {
            if color[vertex] == nil && isBipartite {
                // Start DFS from this unvisited vertex
                color[vertex] = 1 // Assign first color
                visitor?.assignColor?(vertex, 1)
                
                isBipartite = dfsBipartiteCheck(
                    from: vertex,
                    in: graph,
                    color: &color,
                    visitor: visitor
                )
            }
        }
        
        return isBipartite
    }
    
    private func dfsBipartiteCheck(
        from vertex: Graph.VertexDescriptor,
        in graph: Graph,
        color: inout [Graph.VertexDescriptor: Int],
        visitor: Visitor?
    ) -> Bool {
        let currentColor = color[vertex]!
        let nextColor = currentColor == 1 ? 2 : 1
        
        visitor?.examineVertex?(vertex)
        
        // Check all neighbors
        for edge in graph.outgoingEdges(of: vertex) {
            guard let neighbor = graph.destination(of: edge) else { continue }
            
            visitor?.examineEdge?(edge)
            
            if color[neighbor] == nil {
                // Neighbor is uncolored, assign opposite color and recurse
                color[neighbor] = nextColor
                visitor?.assignColor?(neighbor, nextColor)
                
                if !dfsBipartiteCheck(
                    from: neighbor,
                    in: graph,
                    color: &color,
                    visitor: visitor
                ) {
                    return false
                }
            } else if color[neighbor] == currentColor {
                // Neighbor has same color as current vertex
                // This violates bipartite property
                visitor?.colorConflict?(vertex, neighbor, currentColor)
                return false
            }
        }
        
        return true
    }
}

// MARK: - Visitor Support

struct DFSBipartiteProperty<Graph: IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor
    
    struct Visitor {
        var assignColor: ((Vertex, Int) -> Void)?
        var examineVertex: ((Vertex) -> Void)?
        var examineEdge: ((Edge) -> Void)?
        var colorConflict: ((Vertex, Vertex, Int) -> Void)?
    }
}

extension DFSBipartiteProperty.Visitor: Composable {
    func combined(with other: Self) -> Self {
        .init(
            assignColor: { vertex, color in
                self.assignColor?(vertex, color)
                other.assignColor?(vertex, color)
            },
            examineVertex: { vertex in
                self.examineVertex?(vertex)
                other.examineVertex?(vertex)
            },
            examineEdge: { edge in
                self.examineEdge?(edge)
                other.examineEdge?(edge)
            },
            colorConflict: { vertex1, vertex2, color in
                self.colorConflict?(vertex1, vertex2, color)
                other.colorConflict?(vertex1, vertex2, color)
            }
        )
    }
}

extension DFSBipartitePropertyAlgorithm: VisitorSupporting {}
