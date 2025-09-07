extension ShortestPathUntilAlgorithm where Vertex: Hashable, Weight: Numeric, Weight.Magnitude == Weight {
    static func aStar<Vertex, Edge, Weight>(
        weight: @escaping (EdgePropertyValues) -> Weight,
        heuristic: @escaping (Vertex) -> Weight
    ) -> Self where Self == AStarShortestPath<Vertex, Edge, Weight> {
        .init(weight: weight, heuristic: heuristic)
    }
}

struct AStarShortestPath<Vertex: Hashable, Edge, Weight: Numeric>: ShortestPathUntilAlgorithm where Weight.Magnitude == Weight {
    let weight: (EdgePropertyValues) -> Weight
    let heuristic: (Vertex) -> Weight

    func shortestPath(
        from source: Vertex,
        until condition: @escaping (Vertex) -> Bool,
        in graph: some Graph<Vertex, Edge> & IncidenceGraph & VertexListGraph & EdgePropertyGraph
    ) -> Path<Vertex, Edge>? {
        let sequence = AStarAlgorithm(
            on: graph,
            from: source,
            edgeWeight: weight,
            heuristic: heuristic
        )
        guard let result = sequence.first(where: { condition($0.currentVertex) }) else { return nil }
        let destination = result.currentVertex
        return Path(
            source: source,
            destination: destination,
            vertices: result.vertices(to: destination, in: graph),
            edges: result.edges(to: destination, in: graph)
        )
    }
}


