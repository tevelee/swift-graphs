extension ShortestPathAlgorithm {
    static func aStar<Graph: IncidenceGraph, Weight: Numeric>(
        weight: CostAlgorithm<Graph, Weight>,
        heuristic: Heuristic<Graph, Weight>
    ) -> Self where Self == AStarShortestPath<Graph, Weight> {
        .init(weight: weight, heuristic: heuristic)
    }
}

extension AStarShortestPath: ShortestPathAlgorithm {}
