extension ShortestPathAlgorithm where Vertex: Hashable, Weight: Numeric, Weight.Magnitude == Weight {
    static func aStar<Vertex, Edge, Weight>(
        weight: @escaping (EdgePropertyValues) -> Weight,
        heuristic: @escaping (Vertex) -> Weight
    ) -> Self where Self == AStarShortestPath<Vertex, Edge, Weight> {
        .init(weight: weight, heuristic: heuristic)
    }
}

extension AStarShortestPath: ShortestPathAlgorithm {}
