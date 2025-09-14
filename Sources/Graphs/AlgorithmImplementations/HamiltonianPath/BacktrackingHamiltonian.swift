import Foundation

struct BacktrackingHamiltonian<Graph: IncidenceGraph & VertexListGraph> 
where Graph.VertexDescriptor: Hashable {
    
    struct Visitor {
        var examineVertex: ((Graph.VertexDescriptor) -> Void)?
        var examineEdge: ((Graph.EdgeDescriptor) -> Void)?
        var addToPath: ((Graph.VertexDescriptor) -> Void)?
        var removeFromPath: ((Graph.VertexDescriptor) -> Void)?
        var backtrack: ((Graph.VertexDescriptor) -> Void)?
    }
    
    func hamiltonianPath(in graph: Graph, visitor: Visitor? = nil) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        let vertices = Array(graph.vertices())
        guard !vertices.isEmpty else { return nil }
        
        // Try starting from each vertex
        for startVertex in vertices {
            visitor?.examineVertex?(startVertex)
            if let path = findHamiltonianPath(from: startVertex, in: graph, visitor: visitor) {
                return path
            }
        }
        
        return nil
    }
    
    func hamiltonianPath(from source: Graph.VertexDescriptor, in graph: Graph, visitor: Visitor? = nil) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        return findHamiltonianPath(from: source, in: graph, visitor: visitor)
    }
    
    func hamiltonianPath(from source: Graph.VertexDescriptor, to destination: Graph.VertexDescriptor, in graph: Graph, visitor: Visitor? = nil) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        return findHamiltonianPath(from: source, to: destination, in: graph, visitor: visitor)
    }
    
    func hamiltonianCycle(in graph: Graph, visitor: Visitor? = nil) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        let vertices = Array(graph.vertices())
        guard !vertices.isEmpty else { return nil }
        
        // Try starting from each vertex
        for startVertex in vertices {
            visitor?.examineVertex?(startVertex)
            if let cycle = findHamiltonianCycle(from: startVertex, in: graph, visitor: visitor) {
                return cycle
            }
        }
        
        return nil
    }
    
    private func findHamiltonianPath(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        var path: [Graph.VertexDescriptor] = [source]
        var visited: Set<Graph.VertexDescriptor> = [source]
        visitor?.addToPath?(source)
        
        if backtrackPath(
            current: source,
            path: &path,
            visited: &visited,
            target: nil,
            in: graph,
            visitor: visitor
        ) {
            return buildPath(from: path, in: graph)
        }
        
        return nil
    }
    
    private func findHamiltonianPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        var path: [Graph.VertexDescriptor] = [source]
        var visited: Set<Graph.VertexDescriptor> = [source]
        visitor?.addToPath?(source)
        
        if backtrackPath(
            current: source,
            path: &path,
            visited: &visited,
            target: destination,
            in: graph,
            visitor: visitor
        ) {
            return buildPath(from: path, in: graph)
        }
        
        return nil
    }
    
    private func findHamiltonianCycle(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        var path: [Graph.VertexDescriptor] = [source]
        var visited: Set<Graph.VertexDescriptor> = [source]
        visitor?.addToPath?(source)
        
        if backtrackCycle(
            current: source,
            path: &path,
            visited: &visited,
            start: source,
            in: graph,
            visitor: visitor
        ) {
            // Add the starting vertex at the end to complete the cycle
            path.append(source)
            visitor?.addToPath?(source)
            return buildPath(from: path, in: graph)
        }
        
        return nil
    }
    
    private func backtrackPath(
        current: Graph.VertexDescriptor,
        path: inout [Graph.VertexDescriptor],
        visited: inout Set<Graph.VertexDescriptor>,
        target: Graph.VertexDescriptor?,
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool {
        let vertices = Array(graph.vertices())
        
        // If we have a target and reached it, check if all vertices are visited
        if let target = target, current == target {
            return visited.count == vertices.count
        }
        
        // If no target, check if all vertices are visited
        if target == nil && visited.count == vertices.count {
            return true
        }
        
        // Try all unvisited neighbors
        for neighbor in graph.successors(of: current) {
            visitor?.examineVertex?(neighbor)
            
            // Examine edges to neighbors
            for edge in graph.outgoingEdges(of: current) {
                if graph.destination(of: edge) == neighbor {
                    visitor?.examineEdge?(edge)
                }
            }
            
            if !visited.contains(neighbor) {
                path.append(neighbor)
                visited.insert(neighbor)
                visitor?.addToPath?(neighbor)
                
                if backtrackPath(
                    current: neighbor,
                    path: &path,
                    visited: &visited,
                    target: target,
                    in: graph,
                    visitor: visitor
                ) {
                    return true
                }
                
                // Backtrack
                path.removeLast()
                visited.remove(neighbor)
                visitor?.removeFromPath?(neighbor)
                visitor?.backtrack?(neighbor)
            }
        }
        
        return false
    }
    
    private func backtrackCycle(
        current: Graph.VertexDescriptor,
        path: inout [Graph.VertexDescriptor],
        visited: inout Set<Graph.VertexDescriptor>,
        start: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool {
        let vertices = Array(graph.vertices())
        
        // If all vertices visited, check if we can return to start
        if visited.count == vertices.count {
            return graph.successors(of: current).contains(start)
        }
        
        // Try all unvisited neighbors
        for neighbor in graph.successors(of: current) {
            visitor?.examineVertex?(neighbor)
            
            // Examine edges to neighbors
            for edge in graph.outgoingEdges(of: current) {
                if graph.destination(of: edge) == neighbor {
                    visitor?.examineEdge?(edge)
                }
            }
            
            if !visited.contains(neighbor) {
                path.append(neighbor)
                visited.insert(neighbor)
                visitor?.addToPath?(neighbor)
                
                if backtrackCycle(
                    current: neighbor,
                    path: &path,
                    visited: &visited,
                    start: start,
                    in: graph,
                    visitor: visitor
                ) {
                    return true
                }
                
                // Backtrack
                path.removeLast()
                visited.remove(neighbor)
                visitor?.removeFromPath?(neighbor)
                visitor?.backtrack?(neighbor)
            }
        }
        
        return false
    }
    
    private func buildPath(
        from path: [Graph.VertexDescriptor],
        in graph: Graph
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        guard path.count > 0 else { return nil }
        
        // Handle single vertex case
        if path.count == 1 {
            return Path(
                source: path[0],
                destination: path[0],
                vertices: path,
                edges: []
            )
        }
        
        var edges: [Graph.EdgeDescriptor] = []
        
        for i in 0..<(path.count - 1) {
            let from = path[i]
            let to = path[i + 1]
            
            // Find edge between from and to
            if let edge = graph.outgoingEdges(of: from).first(where: { 
                graph.destination(of: $0) == to 
            }) {
                edges.append(edge)
            } else {
                return nil // Invalid path
            }
        }
        
        return Path(
            source: path.first!,
            destination: path.last!,
            vertices: path,
            edges: edges
        )
    }
}

extension BacktrackingHamiltonian: VisitorSupporting {}

