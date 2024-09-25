extension EulerianPathAlgorithm {
    /// Creates a backtracking algorithm instance.
    /// - Returns: An instance of `BacktrackingEulerianPathAlgorithm`.
    @inlinable public static func backtracking<Node, Edge>() -> Self where Self == BacktrackingEulerianPathAlgorithm<Node, Edge> {
        .init()
    }
}

/// An implementation of the backtracking algorithm for finding Eulerian paths and cycles in a graph.
public struct BacktrackingEulerianPathAlgorithm<Node: Hashable, Edge: Hashable>: EulerianPathAlgorithm {
    /// Initializes a new `BacktrackingEulerianPathAlgorithm` instance.
    @inlinable public init() {}

    /// Finds an Eulerian path from the source node to the destination node in the graph using the backtracking algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - destination: The target node.
    ///   - graph: The graph in which to find the Eulerian path.
    /// - Returns: A `Path` instance representing the Eulerian path, or `nil` if no path is found.
    @inlinable public func findEulerianPath(
        from source: Node,
        to destination: Node,
        in graph: some WholeGraphProtocol<Node, Edge>
    ) -> Path<Node, Edge>? {
        guard graph.hasEulerianPath() else { return nil }
        return findEulerianSequence(from: source, to: destination, isCycle: false, in: graph)
    }

    /// Finds an Eulerian cycle from the source node in the graph using the backtracking algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - graph: The graph in which to find the Eulerian cycle.
    /// - Returns: A `Path` instance representing the Eulerian cycle, or `nil` if no cycle is found.
    @inlinable public func findEulerianCycle(
        from source: Node,
        in graph: some WholeGraphProtocol<Node, Edge>
    ) -> Path<Node, Edge>? {
        guard graph.hasEulerianCycle() else { return nil }
        return findEulerianSequence(from: source, to: source, isCycle: true, in: graph)
    }

    /// Finds an Eulerian sequence (path or cycle) in the graph using the backtracking algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - destination: The target node.
    ///   - isCycle: A boolean indicating whether to find a cycle (true) or a path (false).
    ///   - graph: The graph in which to find the Eulerian sequence.
    /// - Returns: A `Path` instance representing the Eulerian sequence, or `nil` if no sequence is found.
    @usableFromInline func findEulerianSequence(
        from source: Node,
        to destination: Node,
        isCycle: Bool,
        in graph: some WholeGraphProtocol<Node, Edge>
    ) -> Path<Node, Edge>? {
        var adjacency: [Node: [GraphEdge<Node, Edge>]] = [:]
        for edge in graph.allEdges {
            adjacency[edge.source, default: []].append(edge)
        }

        let totalEdges = graph.allEdges.count
        var path: [GraphEdge<Node, Edge>] = []

        /// A helper function to perform backtracking to find the Eulerian sequence.
        /// - Parameter current: The current node being visited.
        /// - Returns: A boolean indicating whether the Eulerian sequence has been found.
        func backtrack(current: Node) -> Bool {
            if path.count == totalEdges {
                return current == destination
            }

            guard let edges = adjacency[current], !edges.isEmpty else {
                return false
            }

            for (index, edge) in edges.enumerated() {
                // Choose the edge
                path.append(edge)
                adjacency[current]?.remove(at: index)

                // Explore
                if backtrack(current: edge.destination) {
                    return true
                }

                // Un-choose (backtrack)
                path.removeLast()
                adjacency[current]?.insert(edge, at: index)
            }

            return false
        }

        if backtrack(current: source) {
            return Path(source: source, destination: destination, edges: path)
        }

        return nil
    }
}
