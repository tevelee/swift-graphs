import Collections

extension ShortestPathAlgorithm {
    /// Creates a Dijkstra algorithm instance.
    /// - Returns: An instance of `DijkstraAlgorithm`.
    @inlinable public static func dijkstra<Node, Edge>() -> Self where Self == DijkstraAlgorithm<Node, Edge> {
        .init()
    }
}

extension GraphComponent where Node: Hashable, Edge: Weighted, Edge.Weight: Numeric, Edge.Weight.Magnitude == Edge.Weight {
    /// Finds the shortest path from the source node to the destination node using the Dijkstra algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - destination: The target node.
    /// - Returns: A `Path` instance representing the shortest path, or `nil` if no path is found.
    @inlinable public func shortestPath(
        from source: Node,
        to destination: Node
    ) -> Path<Node, Edge>? {
        shortestPath(from: source, to: destination, using: .dijkstra())
    }
}

/// An implementation of the Dijkstra algorithm for finding the shortest path in a graph.
public struct DijkstraAlgorithm<Node: Hashable, Edge: Weighted>: ShortestPathAlgorithm
where Edge.Weight: Numeric, Edge.Weight.Magnitude == Edge.Weight {
    /// Initializes a new `DijkstraAlgorithm` instance.
    @inlinable public init() {}

    /// Computes the shortest paths from the source node to all other nodes in the graph using the Dijkstra algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - condition: A condition until the algorithm should run.
    ///   - graph: The graph in which to compute the shortest paths.
    /// - Returns: A tuple containing the costs and connecting edges for the shortest paths.
    @usableFromInline func computeShortestPaths(
        from source: Node,
        condition: (Node) -> Bool = { _ in false },
        in graph: some GraphComponent<Node, Edge>
    ) -> (destination: Node?, costs: [Node: Edge.Weight], connectingEdges: [Node: GraphEdge<Node, Edge>]) {
        var openSet = Heap<State>()
        var costs: [Node: Edge.Weight] = [source: .zero]
        var connectingEdges: [Node: GraphEdge<Node, Edge>] = [:]
        var closedSet: Set<Node> = []

        openSet.insert(
            State(
                node: source,
                totalCost: .zero
            )
        )

        var destination: Node?
        while let currentState = openSet.popMin() {
            let currentNode = currentState.node

            if condition(currentNode) {
                destination = currentNode
                break
            }

            if !closedSet.insert(currentNode).inserted {
                continue
            }

            for edge in graph.edges(from: currentNode) {
                let neighbor = edge.destination
                let weight = edge.value.weight
                let newCost = currentState.totalCost + weight

                if costs[neighbor] == nil || newCost < costs[neighbor]! {
                    costs[neighbor] = newCost
                    connectingEdges[neighbor] = edge
                    openSet.insert(State(node: neighbor, totalCost: newCost))
                }
            }
        }

        return (destination, costs, connectingEdges)
    }

    /// A structure representing the state of a node during the Dijkstra search.
    @usableFromInline struct State: Comparable {
        /// The node being evaluated.
        @usableFromInline let node: Node
        /// The total cost of the path to the node.
        @usableFromInline let totalCost: Edge.Weight

        /// Initializes a new `State` instance with the given node and total cost.
        @inlinable init(node: Node, totalCost: Edge.Weight) {
            self.node = node
            self.totalCost = totalCost
        }

        /// Compares two states based on their costs.
        /// - Parameters:
        ///   - lhs: The left-hand side state.
        ///   - rhs: The right-hand side state.
        /// - Returns: `true` if the cost of the left-hand side state is less than that of the right-hand side state, `false` otherwise.
        @inlinable public static func < (lhs: State, rhs: State) -> Bool {
            lhs.totalCost < rhs.totalCost
        }
    }
}
