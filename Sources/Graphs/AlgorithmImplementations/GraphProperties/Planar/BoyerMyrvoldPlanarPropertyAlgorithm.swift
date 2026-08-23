/// Boyer-Myrvold algorithm for planar graph detection.
/// This is the most efficient O(V) algorithm for planarity testing.
public struct BoyerMyrvoldPlanarPropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> where Graph.VertexDescriptor: Hashable {
    public typealias Vertex = Graph.VertexDescriptor
    public typealias Edge = Graph.EdgeDescriptor

    /// An event emitted by the Boyer-Myrvold planarity check.
    public enum Event {
        /// Embedding computation started.
        case embeddingStarted
        /// The biconnected-component check started.
        case biconnectednessCheckStarted
        /// Embedding succeeded.
        case embeddingSucceeded
        /// Embedding failed.
        case embeddingFailed
    }

    /// Typed selectors for Boyer-Myrvold events.
    public enum EventCases {
        /// Selects embedding starts.
        public static var embeddingStarted: AlgorithmEventCase<Event, Void> {
            .init {
                guard case .embeddingStarted = $0 else { return nil }
                return ()
            }
        }

        /// Selects biconnectedness-check starts.
        public static var biconnectednessCheckStarted: AlgorithmEventCase<Event, Void> {
            .init {
                guard case .biconnectednessCheckStarted = $0 else { return nil }
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
    /// observation events are emitted around the decision.
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
        observation?.receive(.biconnectednessCheckStarted)
        let planar = PlanarityCore.isPlanar(graph)
        if planar {
            observation?.receive(.embeddingSucceeded)
        } else {
            observation?.receive(.embeddingFailed)
        }
        return planar
    }
}
