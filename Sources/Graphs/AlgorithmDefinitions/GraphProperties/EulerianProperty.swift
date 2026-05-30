extension IncidenceGraph where Self: VertexListGraph & BidirectionalGraph, VertexDescriptor: Hashable {
    /// Checks if the directed graph has an Eulerian path using connectivity + degree conditions.
    ///
    /// A directed graph has an Eulerian path if and only if:
    /// 1. It's connected (weakly)
    /// 2. At most one vertex has `outDegree - inDegree == 1` (the start vertex)
    /// 3. At most one vertex has `inDegree - outDegree == 1` (the end vertex)
    /// 4. All other vertices have equal in-degree and out-degree
    ///
    /// - Parameter connectivityAlgorithm: The connectivity algorithm to use
    /// - Returns: `true` if the graph has an Eulerian path, `false` otherwise
    @inlinable
    public func hasEulerianPath(
        using connectivityAlgorithm: some ConnectedPropertyAlgorithm<Self>
    ) -> Bool {
        // First check connectivity
        guard isConnected(using: connectivityAlgorithm) else { return false }

        let vertices = Array(vertices())
        if vertices.isEmpty { return false }

        var startVertices = 0  // outDegree - inDegree == 1
        var endVertices = 0  // inDegree - outDegree == 1

        for vertex in vertices {
            let diff = outDegree(of: vertex) - inDegree(of: vertex)
            if diff == 1 {
                startVertices += 1
            } else if diff == -1 {
                endVertices += 1
            } else if diff != 0 {
                return false  // |diff| > 1: no Eulerian path possible
            }
        }

        // Either all balanced (Eulerian cycle, which is also a path), or exactly one start/end
        return (startVertices == 0 && endVertices == 0) || (startVertices == 1 && endVertices == 1)
    }

    /// Checks if the directed graph has an Eulerian cycle using connectivity + degree conditions.
    ///
    /// A directed graph has an Eulerian cycle if and only if:
    /// 1. It's connected (weakly)
    /// 2. Every vertex has equal in-degree and out-degree
    ///
    /// - Parameter connectivityAlgorithm: The connectivity algorithm to use
    /// - Returns: `true` if the graph has an Eulerian cycle, `false` otherwise
    @inlinable
    public func hasEulerianCycle(
        using connectivityAlgorithm: some ConnectedPropertyAlgorithm<Self>
    ) -> Bool {
        // First check connectivity
        guard isConnected(using: connectivityAlgorithm) else { return false }

        let vertices = Array(vertices())
        if vertices.isEmpty { return false }

        for vertex in vertices where inDegree(of: vertex) != outDegree(of: vertex) {
            return false
        }

        return true
    }
}

// MARK: - Default Implementations

extension IncidenceGraph where Self: VertexListGraph & BidirectionalGraph, VertexDescriptor: Hashable {
    /// Checks if the graph has an Eulerian path using DFS-based connectivity algorithm as the default.
    /// This is the most commonly used and efficient algorithm for Eulerian path checking.
    ///
    /// - Returns: `true` if the graph has an Eulerian path, `false` otherwise
    @inlinable
    public func hasEulerianPath() -> Bool {
        hasEulerianPath(using: .dfs())
    }

    /// Checks if the graph has an Eulerian cycle using DFS-based connectivity algorithm as the default.
    /// This is the most commonly used and efficient algorithm for Eulerian cycle checking.
    ///
    /// - Returns: `true` if the graph has an Eulerian cycle, `false` otherwise
    @inlinable
    public func hasEulerianCycle() -> Bool {
        hasEulerianCycle(using: .dfs())
    }
}
