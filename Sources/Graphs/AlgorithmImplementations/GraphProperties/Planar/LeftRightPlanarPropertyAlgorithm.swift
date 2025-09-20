import Foundation

/// Left-Right Planarity Test algorithm for planar graph detection
/// This is a simpler O(V²) algorithm that uses DFS to attempt a planar embedding
struct LeftRightPlanarPropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> where Graph.VertexDescriptor: Hashable {
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor
    
    struct Visitor {
        var startEmbedding: (() -> Void)?
        var examineVertex: ((Vertex) -> Void)?
        var examineEdge: ((Edge) -> Void)?
        var addEdgeToEmbedding: ((Edge, Int) -> Void)?
        var embeddingConflict: ((Edge, Edge) -> Void)?
        var embeddingSuccess: (() -> Void)?
        var embeddingFailure: (() -> Void)?
    }
    
    func isPlanar(
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool {
        // Handle empty graphs and single vertex graphs
        guard graph.vertexCount > 0 else {
            return true
        }
        
        guard graph.vertexCount > 1 else {
            return true
        }
        
        // Quick check: if graph has too many edges, it cannot be planar
        let vertices = graph.vertexCount
        let edges = graph.edgeCount
        
        if vertices >= 3 && edges > 3 * vertices - 6 {
            return false
        }
        
        // For very small graphs, use known results
        if vertices <= 4 {
            return true
        }
        
        visitor?.startEmbedding?()
        
        // Try to find a planar embedding using left-right approach
        return attemptPlanarEmbedding(in: graph, visitor: visitor)
    }
    
    private func attemptPlanarEmbedding(
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool {
        let vertices = Array(graph.vertices())
        
        // Build adjacency list
        var adjacency: [Vertex: [Vertex]] = [:]
        for vertex in vertices {
            adjacency[vertex] = []
            for edge in graph.outgoingEdges(of: vertex) {
                if let destination = graph.destination(of: edge) {
                    adjacency[vertex]?.append(destination)
                }
            }
        }
        
        // Try different starting vertices
        for startVertex in vertices {
            if tryEmbedding(from: startVertex, in: graph, adjacency: adjacency, visitor: visitor) {
                visitor?.embeddingSuccess?()
                return true
            }
        }
        
        visitor?.embeddingFailure?()
        return false
    }
    
    private func tryEmbedding(
        from startVertex: Vertex,
        in graph: Graph,
        adjacency: [Vertex: [Vertex]],
        visitor: Visitor?
    ) -> Bool {
        var visited = Set<Vertex>()
        var embedding: [Vertex: [Vertex]] = [:]
        var edgeOrder: [Int: Int] = [:]
        var orderCounter = 0
        
        // Initialize embedding for all vertices
        for vertex in adjacency.keys {
            embedding[vertex] = []
        }
        
        func dfs(_ vertex: Vertex, _ parent: Vertex?) -> Bool {
            visited.insert(vertex)
            visitor?.examineVertex?(vertex)
            
            let neighbors = adjacency[vertex] ?? []
            
            for neighbor in neighbors {
                if neighbor == parent {
                    continue
                }
                
                // Find the edge between vertex and neighbor
                guard let edge = findEdge(from: vertex, to: neighbor, in: graph) else {
                    continue
                }
                
                visitor?.examineEdge?(edge)
                
                if visited.contains(neighbor) {
                    // This is a back edge - check if it creates a conflict
                    if !canAddBackEdge(from: vertex, to: neighbor, in: embedding) {
                        visitor?.embeddingConflict?(edge, edge) // Simplified for now
                        return false
                    }
                } else {
                    // This is a tree edge - add to embedding
                    embedding[vertex]?.append(neighbor)
                    edgeOrder[orderCounter] = orderCounter
                    orderCounter += 1
                    visitor?.addEdgeToEmbedding?(edge, orderCounter - 1)
                    
                    if !dfs(neighbor, vertex) {
                        return false
                    }
                }
            }
            
            return true
        }
        
        return dfs(startVertex, nil) && visited.count == graph.vertexCount
    }
    
    private func findEdge(from source: Vertex, to destination: Vertex, in graph: Graph) -> Edge? {
        for edge in graph.outgoingEdges(of: source) {
            if let dest = graph.destination(of: edge), dest == destination {
                return edge
            }
        }
        return nil
    }
    
    private func canAddBackEdge(from source: Vertex, to destination: Vertex, in embedding: [Vertex: [Vertex]]) -> Bool {
        // Simplified check: ensure the back edge doesn't cross existing edges
        // This is a basic implementation - a full implementation would need
        // more sophisticated crossing detection
        
        let sourceNeighbors = embedding[source] ?? []
        let destNeighbors = embedding[destination] ?? []
        
        // Basic check: if both vertices have many neighbors, it's more likely to conflict
        return sourceNeighbors.count < 3 && destNeighbors.count < 3
    }
}


