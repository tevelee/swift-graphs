#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    extension SearchAlgorithm {
        /// Creates a uniform cost search algorithm.
        ///
        /// - Parameter edgeWeight: The cost definition for edge weights.
        /// - Returns: A uniform cost search algorithm instance.
        @inlinable
        public static func uniformCostSearch<Graph, Weight>(
            edgeWeight: CostDefinition<Graph, Weight>
        ) -> Self where Self == UniformCostSearchAlgorithm<Graph, Weight> {
            .init(edgeWeight: edgeWeight)
        }
    }

    /// A uniform cost search algorithm implementation for the SearchAlgorithm protocol.
    ///
    /// This struct wraps the core uniform cost search algorithm to provide a
    /// SearchAlgorithm interface, making it easy to use UCS as a general search algorithm.
    ///
    /// - Complexity: O((V + E) log V) where V is the number of vertices and E is the number of edges
    public struct UniformCostSearchAlgorithm<
        Graph: IncidenceGraph,
        Weight: Numeric & Comparable
    >: SearchAlgorithm
    where
        Graph.VertexDescriptor: Hashable,
        Weight.Magnitude == Weight
    {
        public typealias Event = UniformCostSearch<Graph, Weight>.Event

        /// The cost definition for edge weights.
        public let edgeWeight: CostDefinition<Graph, Weight>

        /// Creates a new uniform cost search algorithm.
        ///
        /// - Parameter edgeWeight: The cost definition for edge weights.
        @inlinable
        public init(edgeWeight: CostDefinition<Graph, Weight>) {
            self.edgeWeight = edgeWeight
        }

        /// Performs a uniform cost search from the source vertex.
        ///
        /// - Parameters:
        ///   - source: The vertex to start search from.
        ///   - graph: The graph to search in.
        ///   - observation: An optional observation of the search progress.
        /// - Returns: A uniform cost search algorithm instance.
        @inlinable
        public func search(
            from source: Graph.VertexDescriptor,
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> ObservedAlgorithm<UniformCostSearch<Graph, Weight>> {
            UniformCostSearch(on: graph, from: source, edgeWeight: edgeWeight)
                .observing { event in observation?.receive(event) }
        }
    }

    extension UniformCostSearchAlgorithm: AlgorithmObserving {}
#endif
