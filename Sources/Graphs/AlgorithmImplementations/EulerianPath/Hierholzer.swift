import Foundation

/// Hierholzer's algorithm for finding Eulerian paths and cycles
struct Hierholzer<Graph: BidirectionalGraph & VertexListGraph>: EulerianPathAlgorithm, EulerianCycleAlgorithm 
where Graph.VertexDescriptor: Hashable {
    
    func eulerianPath(in graph: Graph) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        guard graph.hasEulerianPath() else { return nil }
        
        let vertices = Array(graph.vertices())
        
        // Handle empty graph
        if vertices.isEmpty {
            return nil
        }
        
        // Handle single vertex with no edges
        if vertices.count == 1 {
            let vertex = vertices[0]
            if graph.degree(of: vertex) == 0 {
                return Path(source: vertex, destination: vertex, vertices: [vertex], edges: [])
            }
        }
        
        // Find starting vertex (odd degree vertex if exists, otherwise any vertex)
        var startVertex: Graph.VertexDescriptor?
        
        for vertex in vertices {
            if graph.degree(of: vertex) % 2 == 1 {
                startVertex = vertex
                break
            }
        }
        
        // If no odd degree vertex, start from any vertex
        startVertex = startVertex ?? vertices.first
        
        guard let start = startVertex else { return nil }
        
        return findEulerianPath(from: start, in: graph)
    }
    
    func eulerianCycle(in graph: Graph) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        guard graph.hasEulerianCycle() else { return nil }
        
        let vertices = Array(graph.vertices())
        
        // Handle empty graph
        if vertices.isEmpty {
            return nil
        }
        
        // Handle single vertex with no edges
        if vertices.count == 1 {
            let vertex = vertices[0]
            if graph.degree(of: vertex) == 0 {
                return Path(source: vertex, destination: vertex, vertices: [vertex], edges: [])
            }
        }
        
        guard let startVertex = vertices.first else { return nil }
        
        return findEulerianPath(from: startVertex, in: graph)
    }
    
    private func findEulerianPath(
        from start: Graph.VertexDescriptor,
        in graph: Graph
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        var path: [Graph.VertexDescriptor] = []
        var edges: [Graph.EdgeDescriptor] = []
        
        // Create adjacency list with available edges
        var adjacency: [Graph.VertexDescriptor: [Graph.EdgeDescriptor]] = [:]
        let vertices = Array(graph.vertices())
        
        for vertex in vertices {
            adjacency[vertex] = Array(graph.outgoingEdges(of: vertex))
        }
        
        // Hierholzer's algorithm
        var current = start
        var stack: [Graph.VertexDescriptor] = [current]
        
        while !stack.isEmpty {
            if let nextEdge = adjacency[current]?.first {
                // Move to next vertex
                guard let nextVertex = graph.destination(of: nextEdge) else { 
                    adjacency[current]?.removeFirst()
                    continue 
                }
                
                // Remove the used edge
                adjacency[current]?.removeFirst()
                
                stack.append(nextVertex)
                current = nextVertex
            } else {
                // No more edges from current vertex, add to path
                path.append(stack.removeLast())
                if !stack.isEmpty {
                    current = stack.last!
                }
            }
        }
        
        // Reverse to get correct order
        path.reverse()
        
        // Build edge list
        for i in 0..<(path.count - 1) {
            let from = path[i]
            let to = path[i + 1]
            
            // Find edge between from and to
            if let edge = graph.outgoingEdges(of: from).first(where: { 
                graph.destination(of: $0) == to 
            }) {
                edges.append(edge)
            }
        }
        
        guard path.count > 0 else { return nil }
        
        return Path(
            source: path.first!,
            destination: path.last!,
            vertices: path,
            edges: edges
        )
    }
}

