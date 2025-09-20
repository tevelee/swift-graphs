import Foundation

struct BFSBipartitePropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
    typealias Visitor = BFSBipartiteProperty<Graph>.Visitor
    
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
        
        // Process each connected component
        for vertex in graph.vertices() {
            if color[vertex] == nil && isBipartite {
                // Start BFS from this unvisited vertex
                var queue: [Graph.VertexDescriptor] = [vertex]
                color[vertex] = 1 // Assign first color
                visitor?.assignColor?(vertex, 1)
                
                while !queue.isEmpty && isBipartite {
                    let currentVertex = queue.removeFirst()
                    let currentColor = color[currentVertex]!
                    let nextColor = currentColor == 1 ? 2 : 1
                    
                    visitor?.examineVertex?(currentVertex)
                    
                    // Check all neighbors
                    for edge in graph.outgoingEdges(of: currentVertex) {
                        guard let neighbor = graph.destination(of: edge) else { continue }
                        
                        visitor?.examineEdge?(edge)
                        
                        if color[neighbor] == nil {
                            // Neighbor is uncolored, assign opposite color
                            color[neighbor] = nextColor
                            visitor?.assignColor?(neighbor, nextColor)
                            queue.append(neighbor)
                        } else if color[neighbor] == currentColor {
                            // Neighbor has same color as current vertex
                            // This violates bipartite property
                            isBipartite = false
                            visitor?.colorConflict?(currentVertex, neighbor, currentColor)
                            break
                        }
                    }
                }
            }
        }
        
        return isBipartite
    }
}

// MARK: - Visitor Support

struct BFSBipartiteProperty<Graph: IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor
    
    struct Visitor {
        var assignColor: ((Vertex, Int) -> Void)?
        var examineVertex: ((Vertex) -> Void)?
        var examineEdge: ((Edge) -> Void)?
        var colorConflict: ((Vertex, Vertex, Int) -> Void)?
    }
}

extension BFSBipartiteProperty.Visitor: Composable {
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

extension BFSBipartitePropertyAlgorithm: VisitorSupporting {}
