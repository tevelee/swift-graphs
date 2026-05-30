extension IncidenceGraph where Self: VertexListGraph & EdgeListGraph, VertexDescriptor: Hashable {
    /// Computes a straight-line planar drawing of the graph using the specified algorithm.
    ///
    /// - Parameter algorithm: The planar drawing algorithm to use.
    /// - Returns: A drawing assigning integer grid coordinates to every vertex such that no two
    ///   edges cross, or `nil` if the graph is not planar.
    @inlinable
    public func planarDrawing(
        using algorithm: some PlanarDrawingAlgorithm<Self>
    ) -> PlanarDrawing<VertexDescriptor>? {
        algorithm.planarDrawing(in: self, visitor: nil)
    }

    #if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
        /// Computes a straight-line planar drawing using the Chrobak-Payne algorithm as the default.
        ///
        /// - Returns: A drawing assigning integer grid coordinates to every vertex such that no two
        ///   edges cross, or `nil` if the graph is not planar.
        @inlinable
        public func planarDrawing() -> PlanarDrawing<VertexDescriptor>? {
            planarDrawing(using: .chrobakPayne())
        }
    #endif
}

/// A protocol for algorithms that compute a straight-line planar drawing of a graph.
public protocol PlanarDrawingAlgorithm<Graph> {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph & VertexListGraph & EdgeListGraph where Graph.VertexDescriptor: Hashable
    /// The visitor type for observing algorithm progress.
    associatedtype Visitor

    /// Computes a straight-line planar drawing of the graph.
    ///
    /// - Parameters:
    ///   - graph: The graph to draw.
    ///   - visitor: An optional visitor to observe the algorithm progress.
    /// - Returns: The drawing, or `nil` if the graph is not planar.
    func planarDrawing(
        in graph: Graph,
        visitor: Visitor?
    ) -> PlanarDrawing<Graph.VertexDescriptor>?
}

extension VisitorWrapper: PlanarDrawingAlgorithm
where Base: PlanarDrawingAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    public typealias Graph = Base.Graph

    @inlinable
    public func planarDrawing(
        in graph: Base.Graph,
        visitor: Base.Visitor?
    ) -> PlanarDrawing<Base.Graph.VertexDescriptor>? {
        base.planarDrawing(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}

// MARK: - Result Types

/// An integer grid coordinate.
public struct PlanarPoint: Hashable, Sendable {
    /// The horizontal coordinate.
    public let x: Int
    /// The vertical coordinate.
    public let y: Int

    /// Creates a point at `(x, y)`.
    @inlinable
    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

/// A straight-line planar drawing: an assignment of integer grid coordinates to each vertex
/// such that the graph's edges can be drawn as straight segments with no two crossing.
public struct PlanarDrawing<Vertex: Hashable> {
    /// The coordinate assigned to each vertex.
    public let positions: [Vertex: PlanarPoint]

    /// Creates a drawing from a coordinate assignment.
    @inlinable
    public init(positions: [Vertex: PlanarPoint]) {
        self.positions = positions
    }

    /// The coordinate assigned to `vertex`.
    @inlinable
    public func position(of vertex: Vertex) -> PlanarPoint? {
        positions[vertex]
    }

    /// The width of the drawing's bounding box (maximum x-coordinate).
    @inlinable
    public var width: Int {
        positions.values.map(\.x).max() ?? 0
    }

    /// The height of the drawing's bounding box (maximum y-coordinate).
    @inlinable
    public var height: Int {
        positions.values.map(\.y).max() ?? 0
    }
}

extension PlanarDrawing: Sendable where Vertex: Sendable {}
