/// Computes a planar embedding using the Left-Right planarity test
/// (de Fraysseix-Rosenstiehl; Brandes 2009).
///
/// On a planar graph it returns a combinatorial embedding (rotation system); on a non-planar
/// graph it returns a Kuratowski subgraph certificate (a K5 or K3,3 subdivision).
public struct LeftRightPlanarEmbedding<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph>: PlanarEmbeddingAlgorithm
where Graph.VertexDescriptor: Hashable {
    public typealias Vertex = Graph.VertexDescriptor

    /// A visitor that can observe the embedding algorithm's progress.
    public struct Visitor {
        /// Called when the embedding computation starts.
        public var start: (() -> Void)?
        /// Called when the graph is found to be planar (with the resulting embedding).
        public var foundPlanar: ((PlanarEmbedding<Vertex>) -> Void)?
        /// Called when the graph is found to be non-planar (with the certificate).
        public var foundNonPlanar: ((KuratowskiSubgraph<Vertex>) -> Void)?

        /// Creates a new visitor.
        @inlinable
        public init(
            start: (() -> Void)? = nil,
            foundPlanar: ((PlanarEmbedding<Vertex>) -> Void)? = nil,
            foundNonPlanar: ((KuratowskiSubgraph<Vertex>) -> Void)? = nil
        ) {
            self.start = start
            self.foundPlanar = foundPlanar
            self.foundNonPlanar = foundNonPlanar
        }
    }

    /// Creates a new Left-Right planar embedding algorithm.
    @inlinable
    public init() {}

    /// Computes a planar embedding of the graph.
    ///
    /// - Parameters:
    ///   - graph: The graph to embed.
    ///   - visitor: An optional visitor to observe the algorithm progress.
    /// - Returns: The planar embedding result.
    public func planarEmbedding(
        in graph: Graph,
        visitor: Visitor?
    ) -> PlanarEmbeddingResult<Vertex> {
        visitor?.start?()
        let result = PlanarityCore.embeddingResult(graph)
        switch result {
            case .planar(let embedding):
                visitor?.foundPlanar?(embedding)
            case .nonPlanar(let certificate):
                visitor?.foundNonPlanar?(certificate)
        }
        return result
    }
}

extension LeftRightPlanarEmbedding: VisitorSupporting {}

extension PlanarEmbeddingAlgorithm {
    /// Creates a Left-Right planar embedding algorithm.
    ///
    /// - Returns: A new Left-Right planar embedding algorithm.
    @inlinable
    public static func leftRight<Graph>() -> Self where Self == LeftRightPlanarEmbedding<Graph> {
        .init()
    }
}
