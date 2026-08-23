#if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
    /// Bron-Kerbosch clique detection algorithm implementation.
    public struct BronKerboschCliqueDetectionAlgorithm<Graph: IncidenceGraph & VertexListGraph>: CliqueDetectionAlgorithm
    where Graph.VertexDescriptor: Hashable {
        public typealias Event = BronKerboschCliqueDetection<Graph>.Event

        /// Creates a new Bron-Kerbosch clique detection algorithm.
        @inlinable
        public init() {}

        @inlinable
        public func findCliques(
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> CliqueDetectionResult<Graph.VertexDescriptor> {
            let bronKerbosch = BronKerboschCliqueDetection(on: graph)
            return bronKerbosch.findCliques(observation: observation)
        }
    }

    extension CliqueDetectionAlgorithm {
        /// Creates a Bron-Kerbosch clique detection algorithm.
        ///
        /// - Returns: A new Bron-Kerbosch algorithm
        @inlinable
        public static func bronKerbosch<Graph: IncidenceGraph & VertexListGraph>() -> Self
        where Self == BronKerboschCliqueDetectionAlgorithm<Graph>, Graph.VertexDescriptor: Hashable {
            .init()
        }
    }
#endif
