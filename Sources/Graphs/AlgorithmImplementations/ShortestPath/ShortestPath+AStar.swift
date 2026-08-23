#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    extension ShortestPathUntilAlgorithm {
        /// Creates an A* shortest path algorithm with custom cost calculation.
        ///
        /// - Parameters:
        ///   - weight: The cost definition for edge weights
        ///   - heuristic: The heuristic function for estimating remaining cost
        ///   - calculateTotalCost: A function to combine g-score and h-score
        /// - Returns: An A* shortest path algorithm
        @inlinable
        public static func aStar<Graph: IncidenceGraph, Weight: AdditiveArithmetic, HScore, FScore>(
            weight: CostDefinition<Graph, Weight>,
            heuristic: Heuristic<Graph, HScore>,
            calculateTotalCost: @escaping (Weight, HScore) -> FScore
        ) -> Self where Self == AStarShortestPathAlgorithm<Graph, Weight, HScore, FScore> {
            .init(weight: weight, heuristic: heuristic, calculateTotalCost: calculateTotalCost)
        }

        /// Creates an A* shortest path algorithm with simple addition for cost calculation.
        ///
        /// - Parameters:
        ///   - weight: The cost definition for edge weights
        ///   - heuristic: The heuristic function for estimating remaining cost
        /// - Returns: An A* shortest path algorithm
        @inlinable
        public static func aStar<Graph: IncidenceGraph, Weight: AdditiveArithmetic>(
            weight: CostDefinition<Graph, Weight>,
            heuristic: Heuristic<Graph, Weight>
        ) -> Self where Self == AStarShortestPathAlgorithm<Graph, Weight, Weight, Weight> {
            .init(weight: weight, heuristic: heuristic, calculateTotalCost: +)
        }
    }

    extension ShortestPathAlgorithm {
        /// Creates an A* shortest path algorithm with custom cost calculation.
        ///
        /// - Parameters:
        ///   - weight: The cost definition for edge weights
        ///   - heuristic: The heuristic function for estimating remaining cost
        ///   - calculateTotalCost: A function to combine g-score and h-score
        /// - Returns: An A* shortest path algorithm
        @inlinable
        public static func aStar<Graph: IncidenceGraph, Weight: AdditiveArithmetic, HScore, FScore>(
            weight: CostDefinition<Graph, Weight>,
            heuristic: Heuristic<Graph, HScore>,
            calculateTotalCost: @escaping (Weight, HScore) -> FScore
        ) -> Self where Self == AStarShortestPathAlgorithm<Graph, Weight, HScore, FScore> {
            .init(weight: weight, heuristic: heuristic, calculateTotalCost: calculateTotalCost)
        }

        /// Creates an A* shortest path algorithm with simple addition for cost calculation.
        ///
        /// - Parameters:
        ///   - weight: The cost definition for edge weights
        ///   - heuristic: The heuristic function for estimating remaining cost
        /// - Returns: An A* shortest path algorithm
        @inlinable
        public static func aStar<Graph: IncidenceGraph, Weight: AdditiveArithmetic>(
            weight: CostDefinition<Graph, Weight>,
            heuristic: Heuristic<Graph, Weight>
        ) -> Self where Self == AStarShortestPathAlgorithm<Graph, Weight, Weight, Weight> {
            .init(weight: weight, heuristic: heuristic, calculateTotalCost: +)
        }
    }

    /// An A* shortest path algorithm implementation.
    ///
    /// This struct wraps the core A* algorithm to provide both ``ShortestPathAlgorithm``
    /// and ``ShortestPathUntilAlgorithm`` interfaces, supporting point-to-point and condition-based search.
    ///
    /// - Complexity: O((V + E) log V) where V is the number of vertices and E is the number of edges
    public struct AStarShortestPathAlgorithm<
        Graph: IncidenceGraph,
        Weight: AdditiveArithmetic & Comparable,
        HScore: AdditiveArithmetic,
        FScore: Comparable
    >: ShortestPathUntilAlgorithm
    where
        Graph.VertexDescriptor: Hashable
    {
        /// The event type emitted by the core algorithm.
        public typealias Event = AStar<Graph, Weight, HScore, FScore>.Event

        /// The cost definition for edge weights.
        public let weight: CostDefinition<Graph, Weight>
        /// The heuristic function for estimating remaining cost.
        public let heuristic: Heuristic<Graph, HScore>
        /// The function to combine g-score and h-score.
        public let calculateTotalCost: (Weight, HScore) -> FScore

        /// Creates a new A* shortest path algorithm.
        ///
        /// - Parameters:
        ///   - weight: The cost definition for edge weights
        ///   - heuristic: The heuristic function for estimating remaining cost
        ///   - calculateTotalCost: A function to combine g-score and h-score
        @inlinable
        public init(
            weight: CostDefinition<Graph, Weight>,
            heuristic: Heuristic<Graph, HScore>,
            calculateTotalCost: @escaping (Weight, HScore) -> FScore
        ) {
            self.weight = weight
            self.heuristic = heuristic
            self.calculateTotalCost = calculateTotalCost
        }

        /// Finds the shortest path from source until a condition is met using A*.
        ///
        /// - Parameters:
        ///   - source: The source vertex
        ///   - condition: The condition that determines when to stop
        ///   - graph: The graph to search in
        ///   - observation: An optional observation of the algorithm progress
        /// - Returns: The shortest path to the first vertex that satisfies the condition, if one exists
        @inlinable
        public func shortestPath(
            from source: Graph.VertexDescriptor,
            until condition: @escaping (Graph.VertexDescriptor) -> Bool,
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
            let sequence = AStar(
                on: graph,
                from: source,
                edgeWeight: weight,
                heuristic: heuristic,
                calculateTotalCost: calculateTotalCost
            ).makeIterator(observation: observation)
            var iterator = sequence
            while let result = iterator.next() {
                guard condition(result.currentVertex) else { continue }
                let destination = result.currentVertex
                return Path(
                    source: source,
                    destination: destination,
                    vertices: result.vertices(to: destination, in: graph),
                    edges: result.edges(to: destination, in: graph)
                )
            }
            return nil
        }
    }

    extension AStarShortestPathAlgorithm: AlgorithmObserving {}

    // MARK: - Destination-specific A* with HeuristicToDestination

    extension ShortestPathAlgorithm {
        static func aStar<Graph: IncidenceGraph, Weight: AdditiveArithmetic, HScore, FScore>(
            weight: CostDefinition<Graph, Weight>,
            heuristic: HeuristicToDestination<Graph, HScore>,
            calculateTotalCost: @escaping (Weight, HScore) -> FScore
        ) -> Self where Self == AStarShortestPathToDestination<Graph, Weight, HScore, FScore> {
            .init(weight: weight, heuristicForDestination: heuristic, calculateTotalCost: calculateTotalCost)
        }

        static func aStar<Graph: IncidenceGraph, Weight: AdditiveArithmetic>(
            weight: CostDefinition<Graph, Weight>,
            heuristic: HeuristicToDestination<Graph, Weight>
        ) -> Self where Self == AStarShortestPathToDestination<Graph, Weight, Weight, Weight> {
            .init(weight: weight, heuristicForDestination: heuristic, calculateTotalCost: +)
        }
    }

    struct AStarShortestPathToDestination<
        Graph: IncidenceGraph,
        Weight: AdditiveArithmetic & Comparable,
        HScore: AdditiveArithmetic,
        FScore: Comparable
    >: ShortestPathAlgorithm
    where
        Graph.VertexDescriptor: Hashable
    {
        typealias Event = AStar<Graph, Weight, HScore, FScore>.Event

        let weight: CostDefinition<Graph, Weight>
        let heuristicForDestination: HeuristicToDestination<Graph, HScore>
        let calculateTotalCost: (Weight, HScore) -> FScore

        func shortestPath(
            from source: Graph.VertexDescriptor,
            to destination: Graph.VertexDescriptor,
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
            let sequence = AStar(
                on: graph,
                from: source,
                edgeWeight: weight,
                heuristic: heuristicForDestination.estimatedCost(destination),
                calculateTotalCost: calculateTotalCost
            ).makeIterator(observation: observation)
            var iterator = sequence
            while let result = iterator.next() {
                guard result.currentVertex == destination else { continue }
                return Path(
                    source: source,
                    destination: destination,
                    vertices: result.vertices(to: destination, in: graph),
                    edges: result.edges(to: destination, in: graph)
                )
            }
            return nil
        }
    }

    struct HeuristicToDestination<Graph: Graphs.Graph, EstimatedCost> {
        let estimatedCost: (Graph.VertexDescriptor) -> Heuristic<Graph, EstimatedCost>
    }

    #if canImport(simd)
        import simd

        extension HeuristicToDestination where Graph: PropertyGraph {
            static func euclideanDistance<Coordinate: SIMD>(
                of coordinates: @escaping (VertexProperties) -> Coordinate
            ) -> Self where EstimatedCost == Coordinate.Scalar, Coordinate.Scalar: FloatingPoint {
                .init { destination in
                    .euclideanDistance(to: destination, of: coordinates)
                }
            }

            static func manhattanDistance<Coordinate: SIMD>(
                of coordinates: @escaping (VertexProperties) -> Coordinate
            ) -> Self where EstimatedCost == Coordinate.Scalar, Coordinate.Scalar: FloatingPoint {
                .init { destination in
                    .manhattanDistance(to: destination, of: coordinates)
                }
            }
        }
    #endif

    extension AStarShortestPathToDestination: AlgorithmObserving {}
#endif
