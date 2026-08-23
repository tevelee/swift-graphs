#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
    /// Kosaraju's algorithm implementation for strongly connected components.
    public struct KosarajuStronglyConnectedComponentsAlgorithm<Graph: BidirectionalGraph & VertexListGraph>: StronglyConnectedComponentsAlgorithm
    where Graph.VertexDescriptor: Hashable {
        public typealias Event = Kosaraju<Graph>.Event

        /// Creates a new Kosaraju SCC algorithm.
        @inlinable
        public init() {}

        @inlinable
        public func stronglyConnectedComponents(
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> StronglyConnectedComponentsResult<Graph.VertexDescriptor> {
            let kosaraju = Kosaraju(on: graph)
            return kosaraju.stronglyConnectedComponents(observation: observation)
        }
    }

    extension StronglyConnectedComponentsAlgorithm {
        /// Creates a Kosaraju SCC algorithm.
        ///
        /// - Returns: A new Kosaraju SCC algorithm
        @inlinable
        public static func kosaraju<Graph: BidirectionalGraph & VertexListGraph>() -> Self
        where Self == KosarajuStronglyConnectedComponentsAlgorithm<Graph>, Graph.VertexDescriptor: Hashable {
            .init()
        }
    }
#endif
