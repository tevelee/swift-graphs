#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
    /// Union-Find based connected components algorithm implementation.
    public struct UnionFindConnectedComponentsAlgorithm<Graph: IncidenceGraph & VertexListGraph>: ConnectedComponentsAlgorithm
    where Graph.VertexDescriptor: Hashable {
        public typealias Event = UnionFindConnectedComponents<Graph>.Event

        /// Creates a new Union-Find connected components algorithm.
        @inlinable
        public init() {}

        @inlinable
        public func connectedComponents(
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> ConnectedComponentsResult<Graph.VertexDescriptor> {
            let unionFind = UnionFindConnectedComponents(on: graph)
            return unionFind.connectedComponents(observation: observation)
        }
    }

    extension ConnectedComponentsAlgorithm {
        /// Creates a Union-Find connected components algorithm.
        ///
        /// - Returns: A new Union-Find connected components algorithm
        @inlinable
        public static func unionFind<Graph: IncidenceGraph & VertexListGraph>() -> Self
        where Self == UnionFindConnectedComponentsAlgorithm<Graph>, Graph.VertexDescriptor: Hashable {
            .init()
        }
    }
#endif
