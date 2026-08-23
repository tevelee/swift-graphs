/// Computes a straight-line planar grid drawing using the Chrobak-Payne algorithm
/// (a linear-time refinement of de Fraysseix-Pach-Pollack's shift method).
///
/// The graph is embedded (Left-Right test), its embedding is triangulated, a canonical
/// ordering is computed, and vertices are placed by the shift method on an integer grid of
/// size at most `(2n - 4) x (n - 2)`. Returns `nil` for non-planar graphs.
public struct ChrobakPayneDrawing<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph>: PlanarDrawingAlgorithm
where Graph.VertexDescriptor: Hashable {
    public typealias Vertex = Graph.VertexDescriptor

    /// An event emitted while computing a planar drawing.
    public enum Event {
        /// Drawing computation started.
        case started
        /// A drawing was produced.
        case drawingFound(PlanarDrawing<Vertex>)
        /// The graph was found to be non-planar.
        case nonPlanarFound
    }

    /// Typed selectors for planar-drawing events.
    public enum EventCases {
        /// Selects computation start.
        public static var started: AlgorithmEventCase<Event, Void> {
            .init {
                guard case .started = $0 else { return nil }
                return ()
            }
        }

        /// Selects produced drawings.
        public static var drawingFound: AlgorithmEventCase<Event, PlanarDrawing<Vertex>> {
            .init {
                guard case .drawingFound(let drawing) = $0 else { return nil }
                return drawing
            }
        }

        /// Selects non-planar results.
        public static var nonPlanarFound: AlgorithmEventCase<Event, Void> {
            .init {
                guard case .nonPlanarFound = $0 else { return nil }
                return ()
            }
        }
    }

    /// Creates a new Chrobak-Payne planar drawing algorithm.
    @inlinable
    public init() {}

    /// Computes a straight-line planar drawing of the graph.
    ///
    /// - Parameters:
    ///   - graph: The graph to draw.
    ///   - observation: An optional observation of algorithm progress.
    /// - Returns: The drawing, or `nil` if the graph is not planar.
    public func planarDrawing(
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> PlanarDrawing<Vertex>? {
        observation?.receive(.started)
        guard let drawing = PlanarityCore.drawing(graph) else {
            observation?.receive(.nonPlanarFound)
            return nil
        }
        observation?.receive(.drawingFound(drawing))
        return drawing
    }
}

extension PlanarDrawingAlgorithm {
    /// Creates a Chrobak-Payne straight-line planar drawing algorithm.
    ///
    /// - Returns: A new Chrobak-Payne planar drawing algorithm.
    @inlinable
    public static func chrobakPayne<Graph>() -> Self where Self == ChrobakPayneDrawing<Graph> {
        .init()
    }

    /// Creates a straight-line planar drawing algorithm (Chrobak-Payne).
    ///
    /// - Returns: A new Chrobak-Payne planar drawing algorithm.
    @inlinable
    public static func straightLine<Graph>() -> Self where Self == ChrobakPayneDrawing<Graph> {
        .init()
    }
}
