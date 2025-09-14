extension SearchAlgorithm {
    static func aStar<Graph, Weight, HScore, FScore>(
        edgeWeight: CostDefinition<Graph, Weight>,
        heuristic: Heuristic<Graph, HScore>,
        calculateTotalCost: @escaping (Weight, HScore) -> FScore
    ) -> Self where Self == AStarSearch<Graph, Weight, HScore, FScore> {
        .init(edgeWeight: edgeWeight, heuristic: heuristic, calculateTotalCost: calculateTotalCost)
    }
    
    static func aStar<Graph, Weight>(
        edgeWeight: CostDefinition<Graph, Weight>,
        heuristic: Heuristic<Graph, Weight>
    ) -> Self where Self == AStarSearch<Graph, Weight, Weight, Weight> {
        .init(edgeWeight: edgeWeight, heuristic: heuristic, calculateTotalCost: +)
    }
}

struct AStarSearch<
    Graph: IncidenceGraph & EdgePropertyGraph,
    Weight: AdditiveArithmetic & Comparable,
    HScore: AdditiveArithmetic,
    FScore: Comparable
>: SearchAlgorithm where Graph.VertexDescriptor: Hashable {
    let edgeWeight: CostDefinition<Graph, Weight>
    let heuristic: Heuristic<Graph, HScore>
    let calculateTotalCost: (Weight, HScore) -> FScore
    
    init(
        edgeWeight: CostDefinition<Graph, Weight>,
        heuristic: Heuristic<Graph, HScore>,
        calculateTotalCost: @escaping (Weight, HScore) -> FScore
    ) {
        self.edgeWeight = edgeWeight
        self.heuristic = heuristic
        self.calculateTotalCost = calculateTotalCost
    }
    
    func search(
        from source: Graph.VertexDescriptor,
        in graph: Graph
    ) -> AStar<Graph, Weight, HScore, FScore> {
        AStar(
            on: graph,
            from: source,
            edgeWeight: edgeWeight,
            heuristic: heuristic,
            calculateTotalCost: calculateTotalCost
        )
    }
}
