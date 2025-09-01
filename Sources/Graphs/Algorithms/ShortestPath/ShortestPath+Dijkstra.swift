extension ShortestPathAlgorithm where Vertex: Hashable, Weight: Numeric, Weight.Magnitude == Weight {
    static func dijkstra<Vertex, Edge, Weight>(
        weight: @escaping (EdgePropertyValues) -> Weight
    ) -> Self where Self == DijkstraShortestPath<Vertex, Edge, Weight> {
        .init(weight: weight)
    }
}

extension DijkstraShortestPath: ShortestPathAlgorithm {}
