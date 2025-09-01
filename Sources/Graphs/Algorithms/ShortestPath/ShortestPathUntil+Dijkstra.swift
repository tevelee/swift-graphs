extension ShortestPathUntilAlgorithm where Vertex: Hashable, Cost: Numeric, Cost.Magnitude == Cost {
    static func dijkstra<Vertex, Edge, Cost>() -> Self where Self == DijkstraShortestPath<Vertex, Edge, Cost> {
        .init()
    }
}

struct DijkstraShortestPath<Vertex: Hashable, Edge, Cost: Numeric>: ShortestPathUntilAlgorithm where Cost.Magnitude == Cost {
    func shortestPath(
        from source: Vertex,
        until condition: @escaping (Vertex) -> Bool,
        cost: (EdgePropertyValues) -> Cost,
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
        let result = DijkstrasAlgorithm.run(on: graph, from: source, edgeWeight: cost, visitor: visitor)
        guard let destination else { return nil }
        return Path(
            source: source,
            destination: destination,
            vertices: result.vertices(to: destination, in: graph),
            edges: result.edges(to: destination, in: graph)
        )
    }
}
