#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
    /// Tarjan's algorithm implementation for strongly connected components.
    public struct TarjanStronglyConnectedComponentsAlgorithm<Graph: IncidenceGraph & VertexListGraph>: StronglyConnectedComponentsAlgorithm
    where Graph.VertexDescriptor: Hashable {
        public typealias Event = Tarjan<Graph>.Event

        /// Creates a new Tarjan SCC algorithm.
        @inlinable
        public init() {}

        @inlinable
        public func stronglyConnectedComponents(
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> StronglyConnectedComponentsResult<Graph.VertexDescriptor> {
            let tarjan = Tarjan(on: graph)
            return tarjan.stronglyConnectedComponents(observation: observation)
        }
    }

    extension StronglyConnectedComponentsAlgorithm {
        /// Creates a Tarjan SCC algorithm.
        ///
        /// - Returns: A new Tarjan SCC algorithm
        @inlinable
        public static func tarjan<Graph: IncidenceGraph & VertexListGraph>() -> Self
        where Self == TarjanStronglyConnectedComponentsAlgorithm<Graph>, Graph.VertexDescriptor: Hashable {
            .init()
        }
    }
#endif
