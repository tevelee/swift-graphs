extension ShortestPathAlgorithm where Weight: Numeric, Weight.Magnitude == Weight {
    static func dijkstra<Graph, Weight>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == DijkstraShortestPath<Graph, Weight> {
        .init(weight: weight)
    }
}

extension DijkstraShortestPath: ShortestPathAlgorithm {}
