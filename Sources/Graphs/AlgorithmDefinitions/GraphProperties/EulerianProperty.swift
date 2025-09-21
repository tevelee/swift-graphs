import Foundation

// MARK: - Eulerian Path and Cycle Extensions

extension IncidenceGraph where Self: VertexListGraph & BidirectionalGraph, VertexDescriptor: Hashable {
    /// Checks if the graph has an Eulerian path using connectivity + degree conditions.
    /// A graph has an Eulerian path if and only if:
    /// 1. It's connected
    /// 2. It has exactly 0 or 2 vertices of odd degree
    func hasEulerianPath(
        using connectivityAlgorithm: some ConnectedPropertyAlgorithm<Self>
    ) -> Bool {
        // First check connectivity
        guard isConnected(using: connectivityAlgorithm) else { return false }
        
        // Then check degree conditions
        let vertices = Array(vertices())
        if vertices.isEmpty { return false }
        
        var oddDegreeCount = 0
        for vertex in vertices {
            if degree(of: vertex) % 2 == 1 {
                oddDegreeCount += 1
            }
        }
        
        return oddDegreeCount == 0 || oddDegreeCount == 2
    }
    
    /// Checks if the graph has an Eulerian cycle using connectivity + degree conditions.
    /// A graph has an Eulerian cycle if and only if:
    /// 1. It's connected
    /// 2. All vertices have even degree
    func hasEulerianCycle(
        using connectivityAlgorithm: some ConnectedPropertyAlgorithm<Self>
    ) -> Bool {
        // First check connectivity
        guard isConnected(using: connectivityAlgorithm) else { return false }
        
        // Then check degree conditions
        let vertices = Array(vertices())
        if vertices.isEmpty { return false }
        
        for vertex in vertices {
            if degree(of: vertex) % 2 == 1 {
                return false
            }
        }
        
        return true
    }
}

// MARK: - Default Implementations

extension IncidenceGraph where Self: VertexListGraph & BidirectionalGraph, VertexDescriptor: Hashable {
    /// Checks if the graph has an Eulerian path using DFS-based connectivity algorithm as the default.
    /// This is the most commonly used and efficient algorithm for Eulerian path checking.
    func hasEulerianPath() -> Bool {
        hasEulerianPath(using: .dfs())
    }
    
    /// Checks if the graph has an Eulerian cycle using DFS-based connectivity algorithm as the default.
    /// This is the most commonly used and efficient algorithm for Eulerian cycle checking.
    func hasEulerianCycle() -> Bool {
        hasEulerianCycle(using: .dfs())
    }
}
