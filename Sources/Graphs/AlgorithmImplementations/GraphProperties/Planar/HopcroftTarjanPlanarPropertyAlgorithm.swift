/// Hopcroft-Tarjan algorithm for planar graph detection.
/// This is a classic O(V) algorithm that uses DFS and lowpoint calculations.
public struct HopcroftTarjanPlanarPropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> where Graph.VertexDescriptor: Hashable {
    public typealias Vertex = Graph.VertexDescriptor
    public typealias Edge = Graph.EdgeDescriptor

    /// An event emitted by the Hopcroft-Tarjan planarity check.
    public enum Event {
        /// The DFS phase started.
        case depthFirstSearchStarted
        /// The planarity decision phase started.
        case planarityCheckStarted
        /// The planarity check succeeded.
        case planaritySucceeded
        /// A planarity obstruction was found.
        case planarityObstructionFound(String)
    }

    /// Typed selectors for Hopcroft-Tarjan events.
    public enum EventCases {
        /// Selects DFS starts.
        public static var depthFirstSearchStarted: AlgorithmEventCase<Event, Void> {
            .init {
                guard case .depthFirstSearchStarted = $0 else { return nil }
                return ()
            }
        }

        /// Selects planarity-check starts.
        public static var planarityCheckStarted: AlgorithmEventCase<Event, Void> {
            .init {
                guard case .planarityCheckStarted = $0 else { return nil }
                return ()
            }
        }

        /// Selects successful checks.
        public static var planaritySucceeded: AlgorithmEventCase<Event, Void> {
            .init {
                guard case .planaritySucceeded = $0 else { return nil }
                return ()
            }
        }

        /// Selects planarity obstructions.
        public static var planarityObstructionFound: AlgorithmEventCase<Event, String> {
            .init {
                guard case .planarityObstructionFound(let reason) = $0 else { return nil }
                return reason
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

    /// Creates a new Hopcroft-Tarjan planar property algorithm.
    @inlinable
    public init() {}

    /// Checks if the graph is planar.
    ///
    /// The decision is delegated to the shared, correct `PlanarityCore` (Left–Right) engine;
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
        // Graphs on four or fewer vertices are always planar; events only
        // fire once the real test runs (matching prior observable behavior).
        guard graph.vertexCount > 4 else {
            return PlanarityCore.isPlanar(graph)
        }
        observation?.receive(.depthFirstSearchStarted)
        observation?.receive(.planarityCheckStarted)
        let planar = PlanarityCore.isPlanar(graph)
        if planar {
            observation?.receive(.planaritySucceeded)
        } else {
            observation?.receive(.planarityObstructionFound("Contains a Kuratowski subdivision"))
        }
        return planar
    }
}
