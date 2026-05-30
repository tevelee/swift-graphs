extension PlanarityCore {
    /// Computes a straight-line planar drawing of `graph`, or `nil` if the graph is non-planar.
    static func drawing<Graph>(_ graph: Graph) -> PlanarDrawing<Graph.VertexDescriptor>?
    where
        Graph: IncidenceGraph & VertexListGraph & EdgeListGraph,
        Graph.VertexDescriptor: Hashable
    {
        let indexed = indexed(graph)
        let engine = LeftRightPlanarity(n: indexed.vertices.count, adj: indexed.adjacency)
        guard let rotation = engine.planarEmbedding() else { return nil }

        let coordinates = PlanarDrawingCore.positions(rotation: rotation)
        var positions: [Graph.VertexDescriptor: PlanarPoint] = [:]
        positions.reserveCapacity(coordinates.count)
        for (index, coordinate) in coordinates.enumerated() {
            positions[indexed.vertices[index]] = PlanarPoint(x: coordinate.x, y: coordinate.y)
        }
        return PlanarDrawing(positions: positions)
    }
}
