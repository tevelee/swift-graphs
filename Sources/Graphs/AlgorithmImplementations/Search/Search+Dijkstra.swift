#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    extension SearchAlgorithm {
        /// Creates a Dijkstra search algorithm.
        ///
        /// - Parameter edgeWeight: The cost definition for edge weights.
        /// - Returns: A Dijkstra search algorithm instance.
        @inlinable
        public static func dijkstra<Graph, Weight>(
            edgeWeight: CostDefinition<Graph, Weight>
        ) -> Self where Self == DijkstraSearch<Graph, Weight> {
            .init(edgeWeight: edgeWeight)
        }
    }

    /// A Dijkstra search algorithm implementation for the SearchAlgorithm protocol.
    ///
    /// This struct wraps the core Dijkstra algorithm to provide a SearchAlgorithm interface,
    /// making it easy to use Dijkstra as a general search algorithm for finding shortest paths.
    ///
    /// - Complexity: O((V + E) log V) where V is the number of vertices and E is the number of edges
    public struct DijkstraSearch<
        Graph: IncidenceGraph,
        Weight: Numeric & Comparable
    >: SearchAlgorithm
    where
        Graph.VertexDescriptor: Hashable,
        Weight.Magnitude == Weight
    {
        public typealias Event = Dijkstra<Graph, Weight>.Event

        /// The cost definition for edge weights.
        public let edgeWeight: CostDefinition<Graph, Weight>

        /// Creates a new Dijkstra search algorithm.
        ///
        /// - Parameter edgeWeight: The cost definition for edge weights.
        @inlinable
        public init(edgeWeight: CostDefinition<Graph, Weight>) {
            self.edgeWeight = edgeWeight
        }

        /// Performs a Dijkstra search from the source vertex.
        ///
        /// - Parameters:
        ///   - source: The vertex to start search from.
        ///   - graph: The graph to search in.
        ///   - observation: An optional observation of the search progress.
        /// - Returns: A Dijkstra algorithm instance.
        @inlinable
        public func search(
            from source: Graph.VertexDescriptor,
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> ObservedAlgorithm<Dijkstra<Graph, Weight>> {
            Dijkstra(on: graph, from: source, edgeWeight: edgeWeight)
                .observing { event in observation?.receive(event) }
        }
    }

    extension DijkstraSearch: AlgorithmObserving {}
#endif
