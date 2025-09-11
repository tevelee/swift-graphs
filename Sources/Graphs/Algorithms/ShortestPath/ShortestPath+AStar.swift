extension ShortestPathAlgorithm {
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

extension AStarShortestPathUntil: ShortestPathAlgorithm {}

// MARK: - Destination-aware A*

extension ShortestPathAlgorithm {
    static func aStar<Graph: IncidenceGraph, Weight: Numeric, HScore, FScore>(
        weight: CostDefinition<Graph, Weight>,
        heuristic: HeuristicToDestination<Graph, HScore>,
        calculateTotalCost: @escaping (Weight, HScore) -> FScore
    ) -> Self where Self == AStarShortestPathToDestination<Graph, Weight, HScore, FScore> {
        .init(weight: weight, heuristicForDestination: heuristic, calculateTotalCost: calculateTotalCost)
    }

    static func aStar<Graph: IncidenceGraph, Weight: Numeric>(
        weight: CostDefinition<Graph, Weight>,
        heuristic: HeuristicToDestination<Graph, Weight>
    ) -> Self where Self == AStarShortestPathToDestination<Graph, Weight, Weight, Weight> {
        .init(weight: weight, heuristicForDestination: heuristic, calculateTotalCost: +)
    }
}

struct AStarShortestPathToDestination<Graph: IncidenceGraph & EdgePropertyGraph, Weight: Numeric & Comparable, HScore: Numeric, FScore: Comparable>: ShortestPathAlgorithm where Graph.VertexDescriptor: Hashable, HScore.Magnitude == HScore {
    let weight: CostDefinition<Graph, Weight>
    let heuristicForDestination: HeuristicToDestination<Graph, HScore>
    let calculateTotalCost: (Weight, HScore) -> FScore

    func shortestPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        let sequence = AStar(
            on: graph,
            from: source,
            edgeWeight: weight,
            heuristic: heuristicForDestination.estimatedCost(destination),
            calculateTotalCost: calculateTotalCost
        )
        guard let result = sequence.first(where: { $0.currentVertex == destination }) else { return nil }
        return Path(
            source: source,
            destination: destination,
            vertices: result.vertices(to: destination, in: graph),
            edges: result.edges(to: destination, in: graph)
        )
    }
}

struct HeuristicToDestination<Graph: Graphs.Graph, EstimatedCost> {
    let estimatedCost: (Graph.VertexDescriptor) -> Heuristic<Graph, EstimatedCost>
}

extension HeuristicToDestination where Graph: PropertyGraph {
    static func euclideanDistance<Coordinate: SIMD>(
        of coordinates: @escaping (VertexProperties) -> Coordinate
    ) -> Self where EstimatedCost == Coordinate.Scalar, Coordinate.Scalar: FloatingPoint {
        .init { destination in
            .euclideanDistance(to: destination, of: coordinates)
        }
    }
    
    static func manhattanDistance<Coordinate: SIMD>(
        of coordinates: @escaping (VertexProperties) -> Coordinate
    ) -> Self where EstimatedCost == Coordinate.Scalar, Coordinate.Scalar: FloatingPoint {
        .init { destination in
            .manhattanDistance(to: destination, of: coordinates)
        }
    }
}
