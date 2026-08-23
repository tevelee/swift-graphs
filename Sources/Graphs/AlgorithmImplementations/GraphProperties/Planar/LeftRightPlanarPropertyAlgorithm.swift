/// Left-Right Planarity Test algorithm for planar graph detection.
/// This is a simpler O(V²) algorithm that uses DFS to attempt a planar embedding.
public struct LeftRightPlanarPropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> where Graph.VertexDescriptor: Hashable {
    public typealias Vertex = Graph.VertexDescriptor
    public typealias Edge = Graph.EdgeDescriptor

    /// An event emitted by the Left-Right planarity check.
    public enum Event {
        /// Embedding computation started.
        case embeddingStarted
        /// Embedding succeeded.
        case embeddingSucceeded
        /// Embedding failed.
        case embeddingFailed
    }

    /// Typed selectors for Left-Right planarity events.
    public enum EventCases {
        /// Selects embedding starts.
        public static var embeddingStarted: AlgorithmEventCase<Event, Void> {
            .init {
                guard case .embeddingStarted = $0 else { return nil }
                return ()
            }
        }

        /// Selects successful embeddings.
        public static var embeddingSucceeded: AlgorithmEventCase<Event, Void> {
            .init {
                guard case .embeddingSucceeded = $0 else { return nil }
                return ()
            }
        }

        /// Selects failed embeddings.
        public static var embeddingFailed: AlgorithmEventCase<Event, Void> {
            .init {
                guard case .embeddingFailed = $0 else { return nil }
                return ()
            }
        }
    }

    /// Creates a new Left-Right planar property algorithm.
    @inlinable
    public init() {}

    /// Checks if the graph is planar using the Left-Right planarity test.
    ///
    /// This is a genuinely correct, linear-time implementation (de Fraysseix–Rosenstiehl;
    /// Brandes 2009): the decision is delegated to the shared `PlanarityCore` engine, which
    /// also backs `planarEmbedding(...)`.
    ///
    /// - Parameters:
    ///   - graph: The graph to check
    ///   - observation: An optional observation of algorithm progress.
    /// - Returns: `true` if the graph is planar, `false` otherwise
    public func isPlanar(
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> Bool {
        // Graphs on four or fewer vertices are always planar; embedding
        // events only fire once the real test runs (matching prior observable behavior).
        guard graph.vertexCount > 4 else {
            return PlanarityCore.isPlanar(graph)
        }
        observation?.receive(.embeddingStarted)
        let planar = PlanarityCore.isPlanar(graph)
        if planar {
            observation?.receive(.embeddingSucceeded)
        } else {
            observation?.receive(.embeddingFailed)
        }
        return planar
    }
}
