#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
    /// Tarjan's algorithm implementation for articulation points and bridges.
    public struct TarjanArticulationPointsAlgorithm<Graph: IncidenceGraph & VertexListGraph>: ArticulationPointsAlgorithm
    where Graph.VertexDescriptor: Hashable, Graph.EdgeDescriptor: Hashable {
        public typealias Event = TarjanArticulationPoints<Graph>.Event

        /// Creates a new Tarjan articulation points algorithm.
        @inlinable
        public init() {}

        @inlinable
        public func articulationPoints(
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> ArticulationPointsResult<Graph.VertexDescriptor, Graph.EdgeDescriptor> {
            let tarjan = TarjanArticulationPoints(on: graph)
            return tarjan.articulationPoints(observation: observation)
        }
    }

    extension ArticulationPointsAlgorithm {
        /// Creates a Tarjan articulation points algorithm.
        ///
        /// - Returns: A new Tarjan articulation points algorithm
        @inlinable
        public static func tarjan<Graph: IncidenceGraph & VertexListGraph>() -> Self
        where Self == TarjanArticulationPointsAlgorithm<Graph>, Graph.VertexDescriptor: Hashable, Graph.EdgeDescriptor: Hashable {
            .init()
        }
    }
#endif
