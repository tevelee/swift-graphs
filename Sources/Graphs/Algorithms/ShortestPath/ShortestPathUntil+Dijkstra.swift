extension ShortestPathUntilAlgorithm where Vertex: Hashable, Weight: Numeric, Weight.Magnitude == Weight {
    static func dijkstra<Vertex, Edge, Weight>() -> Self where Self == DijkstraShortestPath<Vertex, Edge, Weight> {
        .init()
    }
}

struct DijkstraShortestPath<Vertex: Hashable, Edge, Weight: Numeric>: ShortestPathUntilAlgorithm where Weight.Magnitude == Weight {
    func shortestPath(
        from source: Vertex,
        until condition: @escaping (Vertex) -> Bool,
        weight: (EdgePropertyValues) -> Weight,
        in graph: some Graph<Vertex, Edge> & IncidenceGraph & VertexListGraph & EdgePropertyGraph
    ) -> Path<Vertex, Edge>? {
        var destination: Vertex?
        let visitor = DijkstrasAlgorithm.Visitor<Vertex, Edge>(examineVertex: { vertex in
            if condition(vertex) {
                destination = vertex
                return false
            }
            return true
        })
        let result = DijkstrasAlgorithm.run(on: graph, from: source, edgeWeight: weight, visitor: visitor)
        guard let destination else { return nil }
        return Path(
            source: source,
            destination: destination,
            vertices: result.vertices(to: destination, in: graph),
            edges: result.edges(to: destination, in: graph)
        )
    }
}
