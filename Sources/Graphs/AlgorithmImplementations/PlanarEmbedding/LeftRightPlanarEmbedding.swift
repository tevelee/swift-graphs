/// Computes a planar embedding using the Left-Right planarity test
/// (de Fraysseix-Rosenstiehl; Brandes 2009).
///
/// On a planar graph it returns a combinatorial embedding (rotation system); on a non-planar
/// graph it returns a Kuratowski subgraph certificate (a K5 or K3,3 subdivision).
public struct LeftRightPlanarEmbedding<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph>: PlanarEmbeddingAlgorithm
where Graph.VertexDescriptor: Hashable {
    public typealias Vertex = Graph.VertexDescriptor

    /// An event emitted while computing a planar embedding.
    public enum Event {
        /// Embedding computation started.
        case started
        /// A planar embedding was produced.
        case planarFound(PlanarEmbedding<Vertex>)
        /// A non-planarity certificate was produced.
        case nonPlanarFound(KuratowskiSubgraph<Vertex>)
    }

    /// Typed selectors for planar-embedding events.
    public enum EventCases {
        /// Selects computation start.
        public static var started: AlgorithmEventCase<Event, Void> {
            .init {
                guard case .started = $0 else { return nil }
                return ()
            }
        }

        /// Selects planar embeddings.
        public static var planarFound: AlgorithmEventCase<Event, PlanarEmbedding<Vertex>> {
            .init {
                guard case .planarFound(let embedding) = $0 else { return nil }
                return embedding
            }
        }

        /// Selects non-planarity certificates.
        public static var nonPlanarFound: AlgorithmEventCase<Event, KuratowskiSubgraph<Vertex>> {
            .init {
                guard case .nonPlanarFound(let certificate) = $0 else { return nil }
                return certificate
            }
        }
    }

    /// Creates a new Left-Right planar embedding algorithm.
    @inlinable
    public init() {}

    /// Computes a planar embedding of the graph.
    ///
    /// - Parameters:
    ///   - graph: The graph to embed.
    ///   - observation: An optional observation of algorithm progress.
    /// - Returns: The planar embedding result.
    public func planarEmbedding(
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> PlanarEmbeddingResult<Vertex> {
        observation?.receive(.started)
        let result = PlanarityCore.embeddingResult(graph)
        switch result {
            case .planar(let embedding):
                observation?.receive(.planarFound(embedding))
            case .nonPlanar(let certificate):
                observation?.receive(.nonPlanarFound(certificate))
        }
        return result
    }
}

extension PlanarEmbeddingAlgorithm {
    /// Creates a Left-Right planar embedding algorithm.
    ///
    /// - Returns: A new Left-Right planar embedding algorithm.
    @inlinable
    public static func leftRight<Graph>() -> Self where Self == LeftRightPlanarEmbedding<Graph> {
        .init()
    }
}
