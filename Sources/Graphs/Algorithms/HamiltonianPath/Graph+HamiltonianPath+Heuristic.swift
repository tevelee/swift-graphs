import Collections

extension HamiltonianPathAlgorithm {
    /// Creates a heuristic algorithm instance.
    /// - Parameter heuristic: The heuristic function to use for evaluating nodes.
    /// - Returns: An instance of `HeuristicHamiltonianPathAlgorithm`.
    @inlinable public static func heuristic<Node, Edge>(_ heuristic: Self.Heuristic) -> Self
    where Self == HeuristicHamiltonianPathAlgorithm<Node, Edge> {
        .init(heuristic: heuristic)
    }
}

/// An implementation of a heuristic algorithm for finding Hamiltonian paths and cycles in a graph.
public struct HeuristicHamiltonianPathAlgorithm<Node: Hashable, Edge>: HamiltonianPathAlgorithm {
    /// A structure representing the heuristic function used by the algorithm.
    public struct Heuristic {
        /// A closure that evaluates a node based on the current path and the graph.
        public let evaluate: (_ node: Node, _ path: [Node], _ graph: any Graph<Node, Edge>) -> Double

        /// Initializes a new `Heuristic` instance with the given evaluation closure.
        /// - Parameter evaluate: A closure that evaluates a node based on the current path and the graph.
        @inlinable public init(evaluate: @escaping (Node, [Node], any Graph<Node, Edge>) -> Double) {
            self.evaluate = evaluate
        }
    }

    /// The heuristic function used by the algorithm.
    public let heuristic: Heuristic

    /// Initializes a new `HeuristicHamiltonianPathAlgorithm` instance with the given heuristic.
    /// - Parameter heuristic: The heuristic function to use for evaluating nodes.
    @inlinable public init(heuristic: Heuristic) {
        self.heuristic = heuristic
    }

    /// Finds a Hamiltonian path from the source node to the destination node in the graph using the heuristic algorithm.
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

    /// Finds a Hamiltonian cycle from the source node in the graph using the heuristic algorithm.
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

    /// Finds a Hamiltonian sequence (path or cycle) in the graph using the heuristic algorithm.
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
        var openSet = Heap<State>()
        let initialHeuristic = heuristic.evaluate(source, [source], graph)
        openSet.insert(State(node: source, path: [source], visited: [source], estimatedTotalCost: initialHeuristic))

        while let currentState = openSet.popMin() {
            let currentNode = currentState.node

            if currentState.visited.count == graph.allNodes.count {
                guard isCycle else {
                    let edges = constructEdges(from: currentState.path, withCycle: false, graph: graph)
                    return Path(source: source, destination: destination, edges: edges)
                }
                if graph.edges(from: currentNode).contains(where: { $0.destination == source }) {
                    // Reconstruct the path and append the closing edge
                    let edges = constructEdges(from: currentState.path, withCycle: true, graph: graph)
                    return Path(source: source, destination: destination, edges: edges)
                }
                continue
            }

            // Explore all unvisited neighbors
            for edge in graph.edges(from: currentNode) {
                let neighbor = edge.destination
                if currentState.visited.contains(neighbor) {
                    continue
                }

                // Create a new path by appending the neighbor
                var newPath = currentState.path
                newPath.append(neighbor)

                // Update the visited set
                var newVisited = currentState.visited
                newVisited.insert(neighbor)

                // Calculate the heuristic for the neighbor
                let heuristicValue = heuristic.evaluate(neighbor, newPath, graph)

                // Create a new state and add it to the open set
                let newState = State(
                    node: neighbor,
                    path: newPath,
                    visited: newVisited,
                    estimatedTotalCost: Double(newPath.count) + heuristicValue
                )
                openSet.insert(newState)
            }
        }

        return nil
    }

    @usableFromInline func constructEdges(
        from nodes: [Node],
        withCycle: Bool,
        graph: any Graph<Node, Edge>
    ) -> [GraphEdge<Node, Edge>] {
        var edges: [GraphEdge<Node, Edge>] = []
        for i in 0 ..< nodes.count - 1 {
            let source = nodes[i]
            let destination = nodes[i + 1]
            if let edge = graph.edges(from: source).first(where: { $0.destination == destination }) {
                edges.append(edge)
            }
        }
        if withCycle, let lastEdge = graph.edges(from: nodes.last!).first(where: { $0.destination == nodes.first! }) {
            edges.append(lastEdge)
        }
        return edges
    }

    @usableFromInline struct State: Comparable {
        @usableFromInline let node: Node
        @usableFromInline let path: [Node]
        @usableFromInline let visited: Set<Node>
        @usableFromInline let estimatedTotalCost: Double

        @inlinable init(node: Node, path: [Node], visited: Set<Node>, estimatedTotalCost: Double) {
            self.node = node
            self.path = path
            self.visited = visited
            self.estimatedTotalCost = estimatedTotalCost
        }

        @inlinable static func < (lhs: State, rhs: State) -> Bool {
            lhs.estimatedTotalCost < rhs.estimatedTotalCost
        }
    }
}

extension HeuristicHamiltonianPathAlgorithm.Heuristic {
    /// Creates a heuristic function that evaluates nodes based on the number of edges originating from them.
    @inlinable public static func degree() -> Self {
        .init { node, _, graph in
            Double(graph.edges(from: node).count)
        }
    }

    /// Creates a heuristic function that evaluates nodes based on the distance to the nearest unvisited node.
    @inlinable public static func distance(distanceAlgorithm: DistanceAlgorithm<Node, Double>) -> Self {
        .init { node, path, graph in
            let visited = Set(path)
            let unvisited = graph.allNodes.filter { !visited.contains($0) }
            guard !unvisited.isEmpty else { return .zero }

            let totalDistance = unvisited.reduce(.zero) { sum, unvisitedNode in
                return sum + distanceAlgorithm.distance(node, unvisitedNode)
            }
            return -totalDistance / Double(unvisited.count)
        }
    }
}
