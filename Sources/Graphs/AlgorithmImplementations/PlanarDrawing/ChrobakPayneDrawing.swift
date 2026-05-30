/// Computes a straight-line planar grid drawing using the Chrobak-Payne algorithm
/// (a linear-time refinement of de Fraysseix-Pach-Pollack's shift method).
///
/// The graph is embedded (Left-Right test), its embedding is triangulated, a canonical
/// ordering is computed, and vertices are placed by the shift method on an integer grid of
/// size at most `(2n - 4) x (n - 2)`. Returns `nil` for non-planar graphs.
public struct ChrobakPayneDrawing<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph>: PlanarDrawingAlgorithm
where Graph.VertexDescriptor: Hashable {
    public typealias Vertex = Graph.VertexDescriptor

    /// A visitor that can observe the drawing algorithm's progress.
    public struct Visitor {
        /// Called when the drawing computation starts.
        public var start: (() -> Void)?
        /// Called when a drawing has been produced for a planar graph.
        public var foundDrawing: ((PlanarDrawing<Vertex>) -> Void)?
        /// Called when the graph is non-planar and no drawing exists.
        public var foundNonPlanar: (() -> Void)?

        /// Creates a new visitor.
        @inlinable
        public init(
            start: (() -> Void)? = nil,
            foundDrawing: ((PlanarDrawing<Vertex>) -> Void)? = nil,
            foundNonPlanar: (() -> Void)? = nil
        ) {
            self.start = start
            self.foundDrawing = foundDrawing
            self.foundNonPlanar = foundNonPlanar
        }
    }

    /// Creates a new Chrobak-Payne planar drawing algorithm.
    @inlinable
    public init() {}

    /// Computes a straight-line planar drawing of the graph.
    ///
    /// - Parameters:
    ///   - graph: The graph to draw.
    ///   - visitor: An optional visitor to observe the algorithm progress.
    /// - Returns: The drawing, or `nil` if the graph is not planar.
    public func planarDrawing(
        in graph: Graph,
        visitor: Visitor?
    ) -> PlanarDrawing<Vertex>? {
        visitor?.start?()
        guard let drawing = PlanarityCore.drawing(graph) else {
            visitor?.foundNonPlanar?()
            return nil
        }
        visitor?.foundDrawing?(drawing)
        return drawing
    }
}

extension ChrobakPayneDrawing: VisitorSupporting {}

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
