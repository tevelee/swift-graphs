#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    extension SingleSourceShortestPathAlgorithm {
        /// Creates an SPFA single-source shortest path algorithm.
        ///
        /// - Parameter weight: The cost definition for edge weights.
        /// - Returns: An SPFA shortest path algorithm instance.
        @inlinable
        public static func spfa<Graph: IncidenceGraph & VertexListGraph, Weight: AdditiveArithmetic>(
            weight: CostDefinition<Graph, Weight>
        ) -> Self where Self == SPFAShortestPath<Graph, Weight>, Graph.VertexDescriptor: Hashable {
            .init(weight: weight)
        }
    }

    /// An SPFA shortest path algorithm implementation.
    ///
    /// This struct wraps the core SPFA algorithm to provide a SingleSourceShortestPathAlgorithm interface,
    /// making it easy to compute shortest paths from a single source in graphs with negative weights.
    /// SPFA is a queue-based optimization of Bellman-Ford with average case O(E) complexity.
    ///
    /// - Complexity: Average case O(E), worst case O(VE)
    public struct SPFAShortestPath<
        Graph: IncidenceGraph & VertexListGraph,
        Weight: AdditiveArithmetic & Comparable
    >: SingleSourceShortestPathAlgorithm
    where
        Graph.VertexDescriptor: Hashable
    {
        /// The event type for observing algorithm progress.
        public typealias Event = SPFA<Graph, Weight>.Event

        /// The cost definition for edge weights.
        public let weight: CostDefinition<Graph, Weight>

        /// Creates a new SPFA shortest path algorithm.
        ///
        /// - Parameter weight: The cost definition for edge weights.
        @inlinable
        public init(weight: CostDefinition<Graph, Weight>) {
            self.weight = weight
        }

        /// Computes shortest paths from a single source to all reachable vertices using SPFA.
        ///
        /// - Parameters:
        ///   - source: The source vertex
        ///   - graph: The graph to search in
        ///   - observation: An optional observation to observe the algorithm progress
        /// - Returns: The result containing distances, predecessors, and negative cycle information
        @inlinable
        public func shortestPaths(
            from source: Graph.VertexDescriptor,
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> SingleSourceShortestPaths<Graph.VertexDescriptor, Graph.EdgeDescriptor, Weight> {
            let spfa = SPFA(on: graph, edgeWeight: weight)
            let result = spfa.shortestPathsFromSource(source, observation: observation)
            return SingleSourceShortestPaths(
                distances: result.distances,
                predecessors: result.predecessors,
                hasNegativeCycle: result.hasNegativeCycle
            )
        }
    }

    extension SPFAShortestPath: AlgorithmObserving {}
#endif
