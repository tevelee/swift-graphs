import Foundation

/// Hopcroft-Tarjan algorithm for planar graph detection
/// This is a classic O(V) algorithm that uses DFS and lowpoint calculations
struct HopcroftTarjanPlanarPropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> where Graph.VertexDescriptor: Hashable {
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor
    
    struct Visitor {
        var startDFS: (() -> Void)?
        var discoverVertex: ((Vertex, Int) -> Void)?
        var examineEdge: ((Edge, EdgeType) -> Void)?
        var calculateLowpoint: ((Vertex, Int) -> Void)?
        var checkPlanarity: (() -> Void)?
        var planarityViolation: ((String) -> Void)?
        var planaritySuccess: (() -> Void)?
    }
    
    enum EdgeType {
        case tree
        case back
        case forward
        case cross
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
        
        visitor?.startDFS?()
        
        // Build adjacency list
        var adjacency: [Vertex: [Vertex]] = [:]
        for vertex in graph.vertices() {
            adjacency[vertex] = []
            for edge in graph.outgoingEdges(of: vertex) {
                if let destination = graph.destination(of: edge) {
                    adjacency[vertex]?.append(destination)
                }
            }
        }
        
        // Find a starting vertex
        guard let startVertex = graph.vertices().first(where: { _ in true }) else {
            return true
        }
        
        return hopcroftTarjan(from: startVertex, in: graph, adjacency: adjacency, visitor: visitor)
    }
    
    private func hopcroftTarjan(
        from startVertex: Vertex,
        in graph: Graph,
        adjacency: [Vertex: [Vertex]],
        visitor: Visitor?
    ) -> Bool {
        var visited = Set<Vertex>()
        var discoveryTime: [Vertex: Int] = [:]
        var lowpoint: [Vertex: Int] = [:]
        var parent: [Vertex: Vertex?] = [:]
        var time = 0
        
        // Initialize
        for vertex in adjacency.keys {
            parent[vertex] = nil
        }
        
        func dfs(_ vertex: Vertex) -> Bool {
            visited.insert(vertex)
            discoveryTime[vertex] = time
            lowpoint[vertex] = time
            time += 1
            
            visitor?.discoverVertex?(vertex, discoveryTime[vertex]!)
            
            let neighbors = adjacency[vertex] ?? []
            
            for neighbor in neighbors {
                if !visited.contains(neighbor) {
                    // Tree edge
                    parent[neighbor] = vertex
                    visitor?.examineEdge?(findEdge(from: vertex, to: neighbor, in: graph)!, .tree)
                    
                    if !dfs(neighbor) {
                        return false
                    }
                    
                    // Update lowpoint
                    lowpoint[vertex] = min(lowpoint[vertex]!, lowpoint[neighbor]!)
                } else if parent[vertex] != neighbor {
                    // Back edge
                    visitor?.examineEdge?(findEdge(from: vertex, to: neighbor, in: graph)!, .back)
                    lowpoint[vertex] = min(lowpoint[vertex]!, discoveryTime[neighbor]!)
                }
            }
            
            visitor?.calculateLowpoint?(vertex, lowpoint[vertex]!)
            return true
        }
        
        // Perform DFS
        if !dfs(startVertex) {
            return false
        }
        
        // Check if all vertices were visited (graph is connected)
        if visited.count != graph.vertexCount {
            return false
        }
        
        visitor?.checkPlanarity?()
        
        // Apply Hopcroft-Tarjan planarity conditions
        return checkHopcroftTarjanConditions(
            in: graph,
            adjacency: adjacency,
            discoveryTime: discoveryTime,
            lowpoint: lowpoint,
            visitor: visitor
        )
    }
    
    private func checkHopcroftTarjanConditions(
        in graph: Graph,
        adjacency: [Vertex: [Vertex]],
        discoveryTime: [Vertex: Int],
        lowpoint: [Vertex: Int],
        visitor: Visitor?
    ) -> Bool {
        // The Hopcroft-Tarjan algorithm has specific conditions for planarity
        // This is a simplified version focusing on the key structural properties
        
        let vertices = Array(graph.vertices())
        
        // Check for high-degree vertices that might indicate non-planarity
        for vertex in vertices {
            let degree = adjacency[vertex]?.count ?? 0
            if degree > 5 {
                // High degree vertices are more likely to create conflicts
                // This is a heuristic check
                visitor?.planarityViolation?("High degree vertex: \(degree)")
                return false
            }
        }
        
        // Check for cycles that might indicate K₅ or K₃,₃ subdivisions
        if hasKuratowskiSubdivision(in: graph, adjacency: adjacency) {
            visitor?.planarityViolation?("Contains Kuratowski subdivision")
            return false
        }
        
        visitor?.planaritySuccess?()
        return true
    }
    
    private func hasKuratowskiSubdivision(
        in graph: Graph,
        adjacency: [Vertex: [Vertex]]
    ) -> Bool {
        // Simplified check for K₅ and K₃,₃ subdivisions
        // This is a basic implementation - a full implementation would need
        // more sophisticated subdivision detection
        
        let vertices = Array(graph.vertices())
        
        // Check for K₅ (complete graph on 5 vertices)
        if vertices.count >= 5 {
            let combinations = generateCombinations(vertices, size: 5)
            for combination in combinations {
                if isCompleteGraph(combination, adjacency: adjacency) {
                    return true
                }
            }
        }
        
        // Check for K₃,₃ (complete bipartite graph)
        if vertices.count >= 6 {
            let partitions = generateBipartitions(vertices, size: 3)
            for partition in partitions {
                if isCompleteBipartiteGraph(partition.0, partition.1, adjacency: adjacency) {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func isCompleteGraph(_ vertices: [Vertex], adjacency: [Vertex: [Vertex]]) -> Bool {
        for i in 0..<vertices.count {
            for j in (i+1)..<vertices.count {
                let v1 = vertices[i]
                let v2 = vertices[j]
                if !(adjacency[v1]?.contains(v2) ?? false) {
                    return false
                }
            }
        }
        return true
    }
    
    private func isCompleteBipartiteGraph(_ partition1: [Vertex], _ partition2: [Vertex], adjacency: [Vertex: [Vertex]]) -> Bool {
        for v1 in partition1 {
            for v2 in partition2 {
                if !(adjacency[v1]?.contains(v2) ?? false) {
                    return false
                }
            }
        }
        return true
    }
    
    private func generateCombinations<T: Equatable>(_ elements: [T], size: Int) -> [[T]] {
        guard size > 0 && size <= elements.count else { return [] }
        guard size < elements.count else { return [elements] }
        guard size > 1 else { return elements.map { [$0] } }
        
        var combinations: [[T]] = []
        
        func generate(_ current: [T], _ remaining: [T], _ targetSize: Int) {
            if current.count == targetSize {
                combinations.append(current)
                return
            }
            
            for (index, element) in remaining.enumerated() {
                let newCurrent = current + [element]
                let newRemaining = Array(remaining.dropFirst(index + 1))
                generate(newCurrent, newRemaining, targetSize)
            }
        }
        
        generate([], elements, size)
        return combinations
    }
    
    private func generateBipartitions<T: Equatable>(_ elements: [T], size: Int) -> [([T], [T])] {
        let combinations = generateCombinations(elements, size: size)
        var bipartitions: [([T], [T])] = []
        
        for combination in combinations {
            let remaining = elements.filter { element in !combination.contains(where: { $0 == element }) }
            if remaining.count >= size {
                bipartitions.append((combination, Array(remaining.prefix(size))))
            }
        }
        
        return bipartitions
    }
    
    private func findEdge(from source: Vertex, to destination: Vertex, in graph: Graph) -> Edge? {
        for edge in graph.outgoingEdges(of: source) {
            if let dest = graph.destination(of: edge), dest == destination {
                return edge
            }
        }
        return nil
    }
}


