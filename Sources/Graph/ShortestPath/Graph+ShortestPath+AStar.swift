import Collections

extension ShortestPathAlgorithm {
    /// Creates an A* algorithm instance with a custom heuristic and cost calculation.
    /// - Parameters:
    ///   - heuristic: The heuristic function to estimate the distance from a node to the goal.
    ///   - calculateTotalCost: A closure to calculate the total cost given the edge weight and distance.
    /// - Returns: An instance of `AStarAlgorithm`.
    @inlinable public static func aStar<Node, Edge: Weighted, Distance, Cost: Comparable>(
        heuristic: Self.Heuristic,
        calculateTotalCost: @escaping (Edge.Weight, Distance) -> Cost
    ) -> Self where Self == AStarAlgorithm<Node, Edge, Distance, Cost> {
        .init(heuristic: heuristic, calculateTotalCost: calculateTotalCost)
    }

    /// Creates an A* algorithm instance with a custom heuristic and default cost calculation.
    /// - Parameter heuristic: The heuristic function to estimate the distance from a node to the goal.
    /// - Returns: An instance of `AStarAlgorithm`.
    @inlinable public static func aStar<Node, Edge: Weighted>(
        heuristic: Self.Heuristic
    ) -> Self where Self == AStarAlgorithm<Node, Edge, Edge.Weight, Edge.Weight> {
        .init(heuristic: heuristic, calculateTotalCost: +)
    }

    /// Creates an A* algorithm instance with a custom heuristic for floating-point distances.
    /// - Parameter heuristic: The heuristic function to estimate the distance from a node to the goal.
    /// - Returns: An instance of `AStarAlgorithm`.
    @inlinable public static func aStar<Node, Edge: Weighted, Distance: BinaryFloatingPoint>(
        heuristic: Self.Heuristic
    ) -> Self where Self == AStarAlgorithm<Node, Edge, Distance, Distance>, Edge.Weight: BinaryInteger {
        .init(heuristic: heuristic) { Distance($0) + $1 }
    }
}

extension AStarAlgorithm.Heuristic where HScore: FloatingPoint, HScore.Magnitude == HScore {
    /// Creates a heuristic based on the Euclidean distance.
    /// - Parameter value: A closure to extract the coordinates from a node.
    /// - Returns: An instance of `AStarAlgorithm.Heuristic`.
    @inlinable public static func euclideanDistance<Coordinate: SIMD>(
        of value: @escaping (Node) -> Coordinate
    ) -> Self where HScore == Coordinate.Scalar {
        self.init(distanceAlgorithm: .euclideanDistance(of: value))
    }

    /// Creates a heuristic based on the Manhattan distance.
    /// - Parameter value: A closure to extract the coordinates from a node.
    /// - Returns: An instance of `AStarAlgorithm.Heuristic`.
    @inlinable public static func manhattanDistance<Coordinate: SIMD>(
        of value: @escaping (Node) -> Coordinate
    ) -> Self where HScore == Coordinate.Scalar {
        self.init(distanceAlgorithm: .manhattanDistance(of: value))
    }
}

/// An implementation of the A* algorithm for finding the shortest path in a graph.
public struct AStarAlgorithm<Node: Hashable, Edge: Weighted, HScore, FScore: Comparable>: ShortestPathAlgorithm where Edge.Weight: Numeric {
    /// A heuristic function used by the A* algorithm.
    public struct Heuristic {
        /// A closure to estimate the distance between two nodes.
        public let estimatedDistance: (Node, Node) -> HScore

        /// Initializes a new heuristic with a custom distance estimation function.
        /// - Parameter estimatedDistance: A closure to estimate the distance between two nodes.
        @inlinable public init(estimatedDistance: @escaping (Node, Node) -> HScore) {
            self.estimatedDistance = estimatedDistance
        }

        /// Initializes a new heuristic with a distance algorithm.
        /// - Parameter distanceAlgorithm: A distance algorithm to estimate the distance between two nodes.
        @inlinable public init(distanceAlgorithm: DistanceAlgorithm<Node, HScore>) where HScore.Magnitude == HScore {
            self.init(estimatedDistance: distanceAlgorithm.distance)
        }
    }

    /// The type of the g-score, which represents the cost from the start node to a given node.
    public typealias GScore = Edge.Weight

    /// An implementation of the A* algorithm for finding the shortest path in a graph.
    @usableFromInline let heuristic: Heuristic
    /// A closure to calculate the total cost given the edge weight and distance.
    @usableFromInline let calculateTotalCost: (GScore, HScore) -> FScore

    /// Initializes a new A* algorithm instance with a custom heuristic and cost calculation.
    /// - Parameters:
    ///   - heuristic: The heuristic function to estimate the distance from a node to the goal.
    ///   - calculateTotalCost: A closure to calculate the total cost given the edge weight and distance.
    @inlinable public init(
        heuristic: Heuristic,
        calculateTotalCost: @escaping (Edge.Weight, HScore) -> FScore
    ) {
        self.heuristic = heuristic
        self.calculateTotalCost = calculateTotalCost
    }

    /// Finds the shortest path from the source node to the destination node in the graph.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - destination: The target node.
    ///   - graph: The graph in which to find the shortest path.
    /// - Returns: A `Path` instance representing the shortest path, or `nil` if no path is found.
    @inlinable public func shortestPath(
        from source: Node,
        to destination: Node,
        in graph: some GraphProtocol<Node, Edge>
    ) -> Path<Node, Edge>? {
        var openSet = Heap<State>()
        var costs: [Node: GScore] = [source: .zero]
        var connectingEdges: [Node: GraphEdge<Node, Edge>] = [:]
        var closedSet: Set<Node> = []

        openSet.insert(
            State(
                node: source,
                costSoFar: .zero,
                estimatedTotalCost: calculateTotalCost(.zero, heuristic.estimatedDistance(source, destination))
            )
        )

        while let currentState = openSet.popMin() {
            let currentNode = currentState.node

            if currentNode == destination {
                return Path(connectingEdges: connectingEdges, source: source, destination: destination)
            }

            if !closedSet.insert(currentNode).inserted {
                continue
            }

            for edge in graph.edges(from: currentNode) {
                let neighbor = edge.destination
                let weight: Edge.Weight = edge.value.weight
                let newCost: GScore = currentState.costSoFar + weight

                if costs[neighbor] == nil || newCost < costs[neighbor]! {
                    costs[neighbor] = newCost
                    connectingEdges[neighbor] = edge
                    let estimatedTotalCost = calculateTotalCost(newCost, heuristic.estimatedDistance(neighbor, destination))
                    openSet.insert(State(node: neighbor, costSoFar: newCost, estimatedTotalCost: estimatedTotalCost))
                }
            }
        }

        return nil
    }

    /// Represents a state in the A* algorithm, including the current node, the cost so far, and the estimated total cost.
    @usableFromInline struct State: Comparable {
        /// The current node in the state.
        @usableFromInline let node: Node
        /// The cost from the start node to the current node.
        @usableFromInline let costSoFar: GScore
        /// The estimated total cost from the start node to the goal node through the current node.
        @usableFromInline let estimatedTotalCost: FScore

        /// Initializes a new state with the given node, cost so far, and estimated total cost.
        /// - Parameters:
        ///   - node: The current node.
        ///   - costSoFar: The cost from the start node to the current node.
        ///   - estimatedTotalCost: The estimated total cost from the start node to the goal node through the current node.
        @inlinable init(node: Node, costSoFar: GScore, estimatedTotalCost: FScore) {
            self.node = node
            self.costSoFar = costSoFar
            self.estimatedTotalCost = estimatedTotalCost
        }

        /// Compares two states based on their estimated total cost.
        /// - Parameters:
        ///   - lhs: The left-hand side state.
        ///   - rhs: The right-hand side state.
        /// - Returns: `true` if the estimated total cost of the left-hand side state is less than that of the right-hand side state.
        @inlinable public static func < (lhs: State, rhs: State) -> Bool {
            lhs.estimatedTotalCost < rhs.estimatedTotalCost
        }

        /// Checks if two states are equal based on their node and estimated total cost.
        /// - Parameters:
        ///   - lhs: The left-hand side state.
        ///   - rhs: The right-hand side state.
        /// - Returns: `true` if the node and estimated total cost of both states are equal.
        @inlinable public static func == (lhs: State, rhs: State) -> Bool {
            lhs.node == rhs.node &&
            lhs.estimatedTotalCost == rhs.estimatedTotalCost
        }
    }
}
