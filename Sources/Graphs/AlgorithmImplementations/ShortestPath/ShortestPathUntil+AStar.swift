extension ShortestPathUntilAlgorithm {
    static func aStar<Graph: IncidenceGraph, Weight: AdditiveArithmetic, HScore, FScore>(
        weight: CostDefinition<Graph, Weight>,
        heuristic: Heuristic<Graph, HScore>,
        calculateTotalCost: @escaping (Weight, HScore) -> FScore
    ) -> Self where Self == AStarShortestPathUntil<Graph, Weight, HScore, FScore> {
        .init(weight: weight, heuristic: heuristic, calculateTotalCost: calculateTotalCost)
    }
    
    static func aStar<Graph: IncidenceGraph, Weight: AdditiveArithmetic>(
        weight: CostDefinition<Graph, Weight>,
        heuristic: Heuristic<Graph, Weight>
    ) -> Self where Self == AStarShortestPathUntil<Graph, Weight, Weight, Weight> {
        .init(weight: weight, heuristic: heuristic, calculateTotalCost: +)
    }
}

struct AStarShortestPathUntil<
    Graph: IncidenceGraph & EdgePropertyGraph,
    Weight: AdditiveArithmetic & Comparable,
    HScore: AdditiveArithmetic,
    FScore: Comparable
>: ShortestPathUntilAlgorithm where
    Graph.VertexDescriptor: Hashable
{
    let weight: CostDefinition<Graph, Weight>
    let heuristic: Heuristic<Graph, HScore>
    let calculateTotalCost: (Weight, HScore) -> FScore

    func shortestPath(
        from source: Graph.VertexDescriptor,
        until condition: @escaping (Graph.VertexDescriptor) -> Bool,
        in graph: Graph,
        visitor: AStar<Graph, Weight, HScore, FScore>.Visitor?
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        let sequence = AStar(
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

extension AStarShortestPathUntil: VisitorSupporting {}

