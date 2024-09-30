extension HamiltonianPathAlgorithm {
    /// Creates a backtracking algorithm instance.
    /// - Returns: An instance of `BacktrackingHamiltonianPathAlgorithm`.
    @inlinable public static func backtracking<Node, Edge>() -> Self where Self == BacktrackingHamiltonianPathAlgorithm<Node, Edge> {
        .init()
    }
}

/// An implementation of the backtracking algorithm for finding Hamiltonian paths and cycles in a graph.
public struct BacktrackingHamiltonianPathAlgorithm<Node: Hashable, Edge>: HamiltonianPathAlgorithm {
    /// Initializes a new `BacktrackingHamiltonianPathAlgorithm` instance.
    @inlinable public init() {}

    /// Finds a Hamiltonian path from the source node to the destination node in the graph using the backtracking algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - destination: The target node.
    ///   - graph: The graph in which to find the Hamiltonian path.
    /// - Returns: A `Path` instance representing the Hamiltonian path, or `nil` if no path is found.
    @inlinable public func findHamiltonianPath(
        from source: Node,
        to destination: Node,
        in graph: some Graph<Node, Edge>
    ) -> Path<Node, Edge>? {
        findHamiltonianSequence(from: source, to: destination, isCycle: false, in: graph)
    }

    /// Finds a Hamiltonian cycle from the source node in the graph using the backtracking algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - graph: The graph in which to find the Hamiltonian cycle.
    /// - Returns: A `Path` instance representing the Hamiltonian cycle, or `nil` if no cycle is found.
    @inlinable public func findHamiltonianCycle(
        from source: Node,
        in graph: some Graph<Node, Edge>
    ) -> Path<Node, Edge>? {
        findHamiltonianSequence(from: source, to: source, isCycle: true, in: graph)
    }

    /// Finds a Hamiltonian sequence (path or cycle) in the graph using the backtracking algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - destination: The target node.
    ///   - isCycle: A boolean indicating whether to find a cycle (true) or a path (false).
    ///   - graph: The graph in which to find the Hamiltonian sequence.
    /// - Returns: A `Path` instance representing the Hamiltonian sequence, or `nil` if no sequence is found.
    @usableFromInline func findHamiltonianSequence(
        from source: Node,
        to destination: Node,
        isCycle: Bool,
        in graph: some Graph<Node, Edge>
    ) -> Path<Node, Edge>? {
        let allNodes = Set(graph.allNodes)
        var path: [Node] = [source]
        var visited = Set<Node>([source])
        var resultPath: [GraphEdge<Node, Edge>]?

        /// A helper function to perform backtracking to find the Hamiltonian sequence.
        /// - Parameter current: The current node being visited.
        func backtrack(current: Node) {
            if resultPath != nil {
                return
            }

            if visited.count == allNodes.count {
                if isCycle {
                    if let closingEdge = graph.edges(from: current).first(where: { $0.destination == source }) {
                        let edges = constructEdges(from: path, withCycle: true, closingEdge: closingEdge)
                        resultPath = edges
                    }
                } else {
                    let edges = constructEdges(from: path, withCycle: false, closingEdge: nil)
                    resultPath = edges
                }
                return
            }

            for edge in graph.edges(from: current) {
                let neighbor = edge.destination
                if !visited.contains(neighbor) {
                    // Choose
                    visited.insert(neighbor)
                    path.append(neighbor)

                    // Explore
                    backtrack(current: neighbor)

                    // Un-choose (backtrack)
                    visited.remove(neighbor)
                    path.removeLast()
                }
            }
        }

        func constructEdges(from nodes: [Node], withCycle: Bool, closingEdge: GraphEdge<Node, Edge>?) -> [GraphEdge<Node, Edge>] {
            var edges: [GraphEdge<Node, Edge>] = []
            for i in 0..<nodes.count - 1 {
                let source = nodes[i]
                let destination = nodes[i + 1]
                if let edge = graph.edges(from: source).first(where: { $0.destination == destination }) {
                    edges.append(edge)
                }
            }
            if withCycle, let closingEdge = closingEdge {
                edges.append(closingEdge)
            }
            return edges
        }

        backtrack(current: source)

        if let edges = resultPath {
            return Path(source: source, destination: destination, edges: edges)
        }
        return nil
    }
}
