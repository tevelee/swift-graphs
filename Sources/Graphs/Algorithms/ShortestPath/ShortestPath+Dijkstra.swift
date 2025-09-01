extension ShortestPathAlgorithm where Vertex: Hashable, Weight: Numeric, Weight.Magnitude == Weight {
    static func dijkstra<Vertex, Edge, Weight>() -> Self where Self == DijkstraShortestPath<Vertex, Edge, Weight> {
        .init()
    }
}

extension DijkstraShortestPath: ShortestPathAlgorithm {}
