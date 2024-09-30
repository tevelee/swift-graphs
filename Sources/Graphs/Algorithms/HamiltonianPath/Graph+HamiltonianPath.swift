extension Graph {
    /// Finds a Hamiltonian path from the source node to the destination node using the specified algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - destination: The target node.
    ///   - algorithm: The algorithm to use for finding the Hamiltonian path.
    /// - Returns: A `Path` instance representing the Hamiltonian path, or `nil` if no path is found.
    @inlinable public func hamiltonianPath<Algorithm: HamiltonianPathAlgorithm<Node, Edge>>(
        from source: Node,
        to destination: Node,
        using algorithm: Algorithm
    ) -> Path<Node, Edge>? {
        algorithm.findHamiltonianPath(from: source, to: destination, in: self)
    }

    /// Finds a Hamiltonian path from the source node to the destination node using the default backtracking algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - destination: The target node.
    /// - Returns: A `Path` instance representing the Hamiltonian path, or `nil` if no path is found.
    @inlinable public func hamiltonianPath(
        from source: Node,
        to destination: Node
    ) -> Path<Node, Edge>? where Node: Hashable {
        hamiltonianPath(from: source, to: destination, using: .backtracking())
    }

    /// Finds a Hamiltonian path from the source node using the specified algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - algorithm: The algorithm to use for finding the Hamiltonian path.
    /// - Returns: A `Path` instance representing the Hamiltonian path, or `nil` if no path is found.
    @inlinable public func hamiltonianPath<Algorithm: HamiltonianPathAlgorithm<Node, Edge>>(
        from source: Node,
        using algorithm: Algorithm
    ) -> Path<Node, Edge>? {
        algorithm.findHamiltonianPath(from: source, in: self)
    }

    /// Finds a Hamiltonian path from the source node using the default backtracking algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    /// - Returns: A `Path` instance representing the Hamiltonian path, or `nil` if no path is found.
    @inlinable public func hamiltonianPath(
        from source: Node
    ) -> Path<Node, Edge>? where Node: Hashable {
        hamiltonianPath(from: source, using: .backtracking())
    }

    /// Finds a Hamiltonian cycle from the source node using the specified algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - algorithm: The algorithm to use for finding the Hamiltonian cycle.
    /// - Returns: A `Path` instance representing the Hamiltonian cycle, or `nil` if no cycle is found.
    @inlinable public func hamiltonianCycle<Algorithm: HamiltonianPathAlgorithm<Node, Edge>>(
        from source: Node,
        using algorithm: Algorithm
    ) -> Path<Node, Edge>? {
        algorithm.findHamiltonianCycle(from: source, in: self)
    }

    /// Finds a Hamiltonian cycle from the source node using the default backtracking algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    /// - Returns: A `Path` instance representing the Hamiltonian cycle, or `nil` if no cycle is found.
    @inlinable public func hamiltonianCycle(
        from source: Node
    ) -> Path<Node, Edge>? where Node: Hashable {
        hamiltonianCycle(from: source, using: .backtracking())
    }

    /// Finds a Hamiltonian path using the specified algorithm.
    /// - Parameter algorithm: The algorithm to use for finding the Hamiltonian path.
    /// - Returns: A `Path` instance representing the Hamiltonian path, or `nil` if no path is found.
    @inlinable public func hamiltonianPath<Algorithm: HamiltonianPathAlgorithm<Node, Edge>>(
        using algorithm: Algorithm
    ) -> Path<Node, Edge>? {
        algorithm.findHamiltonianPath(in: self)
    }

    /// Finds a Hamiltonian path using the default backtracking algorithm.
    /// - Returns: A `Path` instance representing the Hamiltonian path, or `nil` if no path is found.
    @inlinable public func hamiltonianPath() -> Path<Node, Edge>? where Node: Hashable {
        hamiltonianPath(using: .backtracking())
    }

    /// Finds a Hamiltonian cycle using the specified algorithm.
    /// - Parameter algorithm: The algorithm to use for finding the Hamiltonian cycle.
    /// - Returns: A `Path` instance representing the Hamiltonian cycle, or `nil` if no cycle is found.
    @inlinable public func hamiltonianCycle<Algorithm: HamiltonianPathAlgorithm<Node, Edge>>(
        using algorithm: Algorithm
    ) -> Path<Node, Edge>? {
        algorithm.findHamiltonianCycle(in: self)
    }

    /// Finds a Hamiltonian cycle using the default backtracking algorithm.
    /// - Returns: A `Path` instance representing the Hamiltonian cycle, or `nil` if no cycle is found.
    @inlinable public func hamiltonianCycle() -> Path<Node, Edge>? where Node: Hashable {
        hamiltonianCycle(using: .backtracking())
    }
}

/// A protocol that defines the requirements for a Hamiltonian path algorithm.
public protocol HamiltonianPathAlgorithm<Node, Edge> {
    /// The type of nodes in the graph.
    associatedtype Node: Hashable
    /// The type of edges in the graph.
    associatedtype Edge

    /// Finds a Hamiltonian path from the source node to the destination node in the graph.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - destination: The target node.
    ///   - graph: The graph in which to find the Hamiltonian path.
    /// - Returns: A `Path` instance representing the Hamiltonian path, or `nil` if no path is found.
    @inlinable func findHamiltonianPath(
        from source: Node,
        to destination: Node,
        in graph: some Graph<Node, Edge>
    ) -> Path<Node, Edge>?

    /// Finds a Hamiltonian path from the source node in the graph.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - graph: The graph in which to find the Hamiltonian path.
    /// - Returns: A `Path` instance representing the Hamiltonian path, or `nil` if no path is found.
    @inlinable func findHamiltonianPath(
        from source: Node,
        in graph: some Graph<Node, Edge>
    ) -> Path<Node, Edge>?

    /// Finds a Hamiltonian path in the graph.
    /// - Parameter graph: The graph in which to find the Hamiltonian path.
    /// - Returns: A `Path` instance representing the Hamiltonian path, or `nil` if no path is found.
    @inlinable func findHamiltonianPath(
        in graph: some Graph<Node, Edge>
    ) -> Path<Node, Edge>?

    /// Finds a Hamiltonian cycle from the source node in the graph.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - graph: The graph in which to find the Hamiltonian cycle.
    /// - Returns: A `Path` instance representing the Hamiltonian cycle, or `nil` if no cycle is found.
    @inlinable func findHamiltonianCycle(
        from source: Node,
        in graph: some Graph<Node, Edge>
    ) -> Path<Node, Edge>?

    /// Finds a Hamiltonian cycle in the graph.
    /// - Parameter graph: The graph in which to find the Hamiltonian cycle.
    /// - Returns: A `Path` instance representing the Hamiltonian cycle, or `nil` if no cycle is found.
    @inlinable func findHamiltonianCycle(
        in graph: some Graph<Node, Edge>
    ) -> Path<Node, Edge>?
}

extension HamiltonianPathAlgorithm {
    /// Finds a Hamiltonian path in the graph.
    /// - Parameter graph: The graph in which to find the Hamiltonian path.
    /// - Returns: A `Path` instance representing the Hamiltonian path, or `nil` if no path is found.
    @inlinable public func findHamiltonianPath(in graph: some Graph<Node, Edge>) -> Path<Node, Edge>? {
        for source in graph.allNodes {
            if let path = findHamiltonianPath(from: source, in: graph) {
                return path
            }
        }
        return nil
    }

    /// Finds a Hamiltonian cycle in the graph.
    /// - Parameter graph: The graph in which to find the Hamiltonian cycle.
    /// - Returns: A `Path` instance representing the Hamiltonian cycle, or `nil` if no cycle is found.
    @inlinable public func findHamiltonianCycle(in graph: some Graph<Node, Edge>) -> Path<Node, Edge>? {
        for startNode in graph.allNodes {
            if let cycle = findHamiltonianCycle(from: startNode, in: graph) {
                return cycle
            }
        }
        return nil
    }

    /// Finds a Hamiltonian path from the source node in the graph.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - graph: The graph in which to find the Hamiltonian path.
    /// - Returns: A `Path` instance representing the Hamiltonian path, or `nil` if no path is found.
    @inlinable public func findHamiltonianPath(from source: Node, in graph: some Graph<Node, Edge>) -> Path<Node, Edge>? {
        for destination in graph.allNodes where destination != source {
            if let path = findHamiltonianPath(from: source, to: destination, in: graph) {
                return path
            }
        }
        return nil
    }
}
