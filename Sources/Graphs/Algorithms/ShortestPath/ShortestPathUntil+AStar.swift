extension ShortestPathUntilAlgorithm {
    static func aStar<Graph: IncidenceGraph, Weight: Numeric, HScore, FScore>(
        weight: CostDefinition<Graph, Weight>,
        heuristic: Heuristic<Graph, HScore>,
        calculateTotalCost: @escaping (Weight, HScore) -> FScore
    ) -> Self where Self == AStarShortestPathUntil<Graph, Weight, HScore, FScore> {
        .init(weight: weight, heuristic: heuristic, calculateTotalCost: calculateTotalCost)
    }
    
    static func aStar<Graph: IncidenceGraph, Weight: Numeric>(
        weight: CostDefinition<Graph, Weight>,
        heuristic: Heuristic<Graph, Weight>
    ) -> Self where Self == AStarShortestPathUntil<Graph, Weight, Weight, Weight> {
        .init(weight: weight, heuristic: heuristic, calculateTotalCost: +)
    }
}

struct AStarShortestPathUntil<Graph: IncidenceGraph & EdgePropertyGraph & VertexListGraph, Weight: Numeric & Comparable, HScore: Numeric, FScore: Comparable>: ShortestPathUntilAlgorithm where Graph.VertexDescriptor: Hashable, HScore.Magnitude == HScore {
    let weight: CostDefinition<Graph, Weight>
    let heuristic: Heuristic<Graph, HScore>
    let calculateTotalCost: (Weight, HScore) -> FScore

    func shortestPath(
        from source: Graph.VertexDescriptor,
        until condition: @escaping (Graph.VertexDescriptor) -> Bool,
        
        in graph: Graph
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        let sequence = AStarAlgorithm(
            on: graph,
            from: source,
            edgeWeight: weight,
            heuristic: heuristic,
            calculateTotalCost: calculateTotalCost
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


