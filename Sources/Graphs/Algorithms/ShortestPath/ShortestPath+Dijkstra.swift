extension ShortestPathAlgorithm where Vertex: Hashable, Cost: Numeric, Cost.Magnitude == Cost {
    static func dijkstra<Vertex, Edge, Cost>() -> Self where Self == DijkstraShortestPath<Vertex, Edge, Cost> {
        .init()
    }
}

extension DijkstraShortestPath: ShortestPathAlgorithm {}
