#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    extension ShortestPathsForAllPairsAlgorithm where Weight: AdditiveArithmetic {
        /// Creates a Floyd-Warshall algorithm for computing all-pairs shortest paths.
        ///
        /// - Parameter weight: The cost definition for edge weights.
        /// - Returns: A Floyd-Warshall algorithm instance.
        @inlinable
        public static func floydWarshall<Graph: IncidenceGraph & VertexListGraph, Weight>(
            weight: CostDefinition<Graph, Weight>
        ) -> Self where Self == FloydWarshallAllPairs<Graph, Weight>, Graph.VertexDescriptor: Hashable {
            .init(weight: weight)
        }
    }

    /// A Floyd-Warshall algorithm implementation for all-pairs shortest paths.
    public struct FloydWarshallAllPairs<
        Graph: IncidenceGraph & VertexListGraph,
        Weight: AdditiveArithmetic & Comparable
    >: ShortestPathsForAllPairsAlgorithm
    where
        Graph.VertexDescriptor: Hashable
    {
        /// The event type for this algorithm.
        public typealias Event = FloydWarshall<Graph, Weight>.Event

        /// The cost definition for edge weights.
        public let weight: CostDefinition<Graph, Weight>

        /// Creates a new Floyd-Warshall all-pairs algorithm.
        ///
        /// - Parameter weight: The cost definition for edge weights.
        @inlinable
        public init(weight: CostDefinition<Graph, Weight>) {
            self.weight = weight
        }

        /// Computes shortest paths between all pairs of vertices.
        ///
        /// - Parameters:
        ///   - graph: The graph to compute shortest paths for.
        ///   - observation: An optional observation to observe the algorithm's progress.
        /// - Returns: The shortest paths between all pairs of vertices.
        @inlinable
        public func shortestPathsForAllPairs(
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> AllPairsShortestPaths<Graph.VertexDescriptor, Graph.EdgeDescriptor, Weight> {
            let floydWarshall = FloydWarshall(on: graph, edgeWeight: weight)
            return floydWarshall.shortestPathsForAllPairs(observation: observation)
        }
    }

    extension FloydWarshallAllPairs: AlgorithmObserving {}
#endif
