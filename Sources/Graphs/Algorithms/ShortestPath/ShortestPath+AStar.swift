extension ShortestPathAlgorithm {
    static func aStar<Graph: IncidenceGraph, Weight: Numeric, HScore, FScore>(
        weight: CostDefinition<Graph, Weight>,
        heuristic: Heuristic<Graph, HScore>,
        calculateTotalCost: @escaping (Weight, HScore) -> FScore
    ) -> Self where Self == AStarShortestPath<Graph, Weight, HScore, FScore> {
        .init(weight: weight, heuristic: heuristic, calculateTotalCost: calculateTotalCost)
    }
    
    static func aStar<Graph: IncidenceGraph, Weight: Numeric>(
        weight: CostDefinition<Graph, Weight>,
        heuristic: Heuristic<Graph, Weight>
    ) -> Self where Self == AStarShortestPath<Graph, Weight, Weight, Weight> {
        .init(weight: weight, heuristic: heuristic, calculateTotalCost: +)
    }
}

extension AStarShortestPath: ShortestPathAlgorithm {}
