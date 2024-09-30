extension Graph {
    /// Finds an Eulerian path from the source to the destination using the specified algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - destination: The ending node.
    ///   - algorithm: The algorithm to use for finding the Eulerian path.
    /// - Returns: A `Path` instance representing the Eulerian path, or `nil` if no path is found.
    @inlinable public func eulerianPath<Algorithm: EulerianPathAlgorithm<Node, Edge>>(
        from source: Node,
        to destination: Node,
        using algorithm: Algorithm
    ) -> Path<Node, Edge>? {
        algorithm.findEulerianPath(from: source, to: destination, in: self)
    }

    /// Finds an Eulerian path from the source to the destination using the default backtracking algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - destination: The ending node.
    /// - Returns: A `Path` instance representing the Eulerian path, or `nil` if no path is found.
    @inlinable public func eulerianPath(
        from source: Node,
        to destination: Node
    ) -> Path<Node, Edge>? where Node: Hashable, Edge: Hashable {
        eulerianPath(from: source, to: destination, using: .backtracking())
    }

    /// Finds an Eulerian path from the source node using the specified algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - algorithm: The algorithm to use for finding the Eulerian path.
    /// - Returns: A `Path` instance representing the Eulerian path, or `nil` if no path is found.
    @inlinable public func eulerianPath<Algorithm: EulerianPathAlgorithm<Node, Edge>>(
        from source: Node,
        using algorithm: Algorithm
    ) -> Path<Node, Edge>? {
        algorithm.findEulerianPath(from: source, in: self)
    }

    /// Finds an Eulerian path from the source node using the default backtracking algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    /// - Returns: A `Path` instance representing the Eulerian path, or `nil` if no path is found.
    @inlinable public func eulerianPath(
        from source: Node
    ) -> Path<Node, Edge>? where Node: Hashable, Edge: Hashable {
        eulerianPath(from: source, using: .backtracking())
    }

    /// Finds an Eulerian path using the specified algorithm.
    /// - Parameter algorithm: The algorithm to use for finding the Eulerian path.
    /// - Returns: A `Path` instance representing the Eulerian path, or `nil` if no path is found.
    @inlinable public func eulerianPath<Algorithm: EulerianPathAlgorithm<Node, Edge>>(
        using algorithm: Algorithm
    ) -> Path<Node, Edge>? {
        algorithm.findEulerianPath(in: self)
    }

    /// Finds an Eulerian path using the default backtracking algorithm.
    /// - Returns: A `Path` instance representing the Eulerian path, or `nil` if no path is found.
    @inlinable public func eulerianPath() -> Path<Node, Edge>? where Node: Hashable, Edge: Hashable {
        eulerianPath(using: .backtracking())
    }

    /// Finds an Eulerian cycle from the source node using the specified algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - algorithm: The algorithm to use for finding the Eulerian cycle.
    /// - Returns: A `Path` instance representing the Eulerian cycle, or `nil` if no cycle is found.
    @inlinable public func eulerianCycle<Algorithm: EulerianPathAlgorithm<Node, Edge>>(
        from source: Node,
        using algorithm: Algorithm
    ) -> Path<Node, Edge>? {
        algorithm.findEulerianCycle(from: source, in: self)
    }

    /// Finds an Eulerian cycle from the source node using the default backtracking algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    /// - Returns: A `Path` instance representing the Eulerian cycle, or `nil` if no cycle is found.
    @inlinable public func eulerianCycle(
        from source: Node
    ) -> Path<Node, Edge>? where Node: Hashable, Edge: Hashable {
        eulerianCycle(from: source, using: .backtracking())
    }

    /// Finds an Eulerian cycle using the specified algorithm.
    /// - Parameter algorithm: The algorithm to use for finding the Eulerian cycle.
    /// - Returns: A `Path` instance representing the Eulerian cycle, or `nil` if no cycle is found.
    @inlinable public func eulerianCycle<Algorithm: EulerianPathAlgorithm<Node, Edge>>(
        using algorithm: Algorithm
    ) -> Path<Node, Edge>? {
        algorithm.findEulerianCycle(in: self)
    }


    /// Finds an Eulerian cycle using the default backtracking algorithm.
    /// - Returns: A `Path` instance representing the Eulerian cycle, or `nil` if no cycle is found.
    @inlinable public func eulerianCycle() -> Path<Node, Edge>? where Node: Hashable, Edge: Hashable {
        eulerianCycle(using: .backtracking())
    }
}

/// A protocol defining the requirements for an Eulerian path algorithm.
public protocol EulerianPathAlgorithm<Node, Edge> {
    associatedtype Node: Hashable
    associatedtype Edge

    /// Finds an Eulerian path from the source to the destination in the given graph.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - destination: The ending node.
    ///   - graph: The graph in which to find the Eulerian path.
    /// - Returns: A `Path` instance representing the Eulerian path, or `nil` if no path is found.
    @inlinable func findEulerianPath(
        from source: Node,
        to destination: Node,
        in graph: some Graph<Node, Edge>
    ) -> Path<Node, Edge>?

    /// Finds an Eulerian path from the source in the given graph.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - graph: The graph in which to find the Eulerian path.
    /// - Returns: A `Path` instance representing the Eulerian path, or `nil` if no path is found.
    @inlinable func findEulerianPath(
        from source: Node,
        in graph: some Graph<Node, Edge>
    ) -> Path<Node, Edge>?

    /// Finds an Eulerian path in the given graph.
    /// - Parameter graph: The graph in which to find the Eulerian path.
    /// - Returns: A `Path` instance representing the Eulerian path, or `nil` if no path is found.
    @inlinable func findEulerianPath(
        in graph: some Graph<Node, Edge>
    ) -> Path<Node, Edge>?

    /// Finds an Eulerian cycle from the source in the given graph.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - graph: The graph in which to find the Eulerian cycle.
    /// - Returns: A `Path` instance representing the Eulerian cycle, or `nil` if no cycle is found.
    @inlinable func findEulerianCycle(
        from source: Node,
        in graph: some Graph<Node, Edge>
    ) -> Path<Node, Edge>?

    /// Finds an Eulerian cycle in the given graph.
    /// - Parameter graph: The graph in which to find the Eulerian cycle.
    /// - Returns: A `Path` instance representing the Eulerian cycle, or `nil` if no cycle is found.
    @inlinable func findEulerianCycle(
        in graph: some Graph<Node, Edge>
    ) -> Path<Node, Edge>?
}

extension EulerianPathAlgorithm {
    /// Finds an Eulerian path in the graph.
    /// - Parameter graph: The graph in which to find the Eulerian path.
    /// - Returns: A `Path` instance representing the Eulerian path, or `nil` if no path is found.
    @inlinable public func findEulerianPath(in graph: some Graph<Node, Edge>) -> Path<Node, Edge>? {
        guard graph.hasEulerianPath() else { return nil }

        for source in graph.allNodes {
            if let path = findEulerianPath(from: source, in: graph) {
                return path
            }
        }
        return nil
    }

    /// Finds an Eulerian cycle in the graph.
    /// - Parameter graph: The graph in which to find the Eulerian cycle.
    /// - Returns: A `Path` instance representing the Eulerian cycle, or `nil` if no cycle is found.
    @inlinable public func findEulerianCycle(in graph: some Graph<Node, Edge>) -> Path<Node, Edge>? {
        guard graph.hasEulerianCycle() else { return nil }

        for startNode in graph.allNodes {
            if let cycle = findEulerianCycle(from: startNode, in: graph) {
                return cycle
            }
        }
        return nil
    }

    /// Finds an Eulerian path from the source node in the graph.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - graph: The graph in which to find the Eulerian path.
    /// - Returns: A `Path` instance representing the Eulerian path, or `nil` if no path is found.
    @inlinable public func findEulerianPath(from source: Node, in graph: some Graph<Node, Edge>) -> Path<Node, Edge>? {
        guard graph.hasEulerianPath() else { return nil }

        for destination in graph.allNodes where destination != source {
            if let path = findEulerianPath(from: source, to: destination, in: graph) {
                return path
            }
        }
        return nil
    }
}
