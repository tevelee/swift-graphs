/// Boyer-Myrvold algorithm for planar graph detection.
/// This is the most efficient O(V) algorithm for planarity testing.
public struct BoyerMyrvoldPlanarPropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> where Graph.VertexDescriptor: Hashable {
    public typealias Vertex = Graph.VertexDescriptor
    public typealias Edge = Graph.EdgeDescriptor

    /// A visitor that can be used to observe the Boyer-Myrvold algorithm progress.
    public struct Visitor {
        /// Called when starting the embedding process.
        public var startEmbedding: (() -> Void)?
        /// Called when examining a vertex.
        public var examineVertex: ((Vertex, Int) -> Void)?
        /// Called when examining an edge.
        public var examineEdge: ((Edge, EdgeType) -> Void)?
        /// Called when adding a vertex to the embedding.
        public var addToEmbedding: ((Vertex, [Vertex]) -> Void)?
        /// Called when checking biconnected components.
        public var checkBiconnected: (() -> Void)?
        /// Called when an embedding conflict is detected.
        public var embeddingConflict: ((Edge, Edge) -> Void)?
        /// Called when embedding succeeds.
        public var embeddingSuccess: (() -> Void)?
        /// Called when embedding fails.
        public var embeddingFailure: (() -> Void)?

        /// Creates a new visitor.
        @inlinable
        public init(
            startEmbedding: (() -> Void)? = nil,
            examineVertex: ((Vertex, Int) -> Void)? = nil,
            examineEdge: ((Edge, EdgeType) -> Void)? = nil,
            addToEmbedding: ((Vertex, [Vertex]) -> Void)? = nil,
            checkBiconnected: (() -> Void)? = nil,
            embeddingConflict: ((Edge, Edge) -> Void)? = nil,
            embeddingSuccess: (() -> Void)? = nil,
            embeddingFailure: (() -> Void)? = nil
        ) {
            self.startEmbedding = startEmbedding
            self.examineVertex = examineVertex
            self.examineEdge = examineEdge
            self.addToEmbedding = addToEmbedding
            self.checkBiconnected = checkBiconnected
            self.embeddingConflict = embeddingConflict
            self.embeddingSuccess = embeddingSuccess
            self.embeddingFailure = embeddingFailure
        }
    }

    /// Types of edges in the DFS tree.
    public enum EdgeType {
        /// Tree edge (part of the DFS tree).
        case tree
        /// Back edge (connects to ancestor).
        case back
        /// Forward edge (connects to descendant).
        case forward
        /// Cross edge (connects across subtrees).
        case cross
    }

    /// Creates a new Boyer-Myrvold planar property algorithm.
    @inlinable
    public init() {}

    /// Checks if the graph is planar.
    ///
    /// The decision is delegated to the shared, correct `PlanarityCore` (Left-Right) engine;
    /// the visitor's embedding events are emitted around the decision.
    ///
    /// - Parameters:
    ///   - graph: The graph to check
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: `true` if the graph is planar, `false` otherwise
    public func isPlanar(
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool {
        // Graphs on four or fewer vertices are always planar; the visitor's embedding
        // events only fire once the real test runs (matching prior observable behavior).
        guard graph.vertexCount > 4 else {
            return PlanarityCore.isPlanar(graph)
        }
        visitor?.startEmbedding?()
        visitor?.checkBiconnected?()
        let planar = PlanarityCore.isPlanar(graph)
        if planar {
            visitor?.embeddingSuccess?()
        } else {
            visitor?.embeddingFailure?()
        }
        return planar
    }
}
