extension ShortestPathAlgorithm {
    static func aStar<Graph: IncidenceGraph, Weight: AdditiveArithmetic, HScore, FScore>(
        weight: CostDefinition<Graph, Weight>,
        heuristic: Heuristic<Graph, HScore>,
        calculateTotalCost: @escaping (Weight, HScore) -> FScore
    ) -> Self where Self == AStarShortestPathAlgorithm<Graph, Weight, HScore, FScore> {
        .init(weight: weight, heuristic: heuristic, calculateTotalCost: calculateTotalCost)
    }
    
    static func aStar<Graph: IncidenceGraph, Weight: AdditiveArithmetic>(
        weight: CostDefinition<Graph, Weight>,
        heuristic: Heuristic<Graph, Weight>
    ) -> Self where Self == AStarShortestPathAlgorithm<Graph, Weight, Weight, Weight> {
        .init(weight: weight, heuristic: heuristic, calculateTotalCost: +)
    }
}

struct AStarShortestPathAlgorithm<
    Graph: IncidenceGraph & EdgePropertyGraph,
    Weight: AdditiveArithmetic & Comparable,
    HScore: AdditiveArithmetic,
    FScore: Comparable
>: ShortestPathAlgorithm where
    Graph.VertexDescriptor: Hashable
{
    typealias Visitor = AStar<Graph, Weight, HScore, FScore>.Visitor
    
    let weight: CostDefinition<Graph, Weight>
    let heuristic: Heuristic<Graph, HScore>
    let calculateTotalCost: (Weight, HScore) -> FScore

    func shortestPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        let sequence = AStar(
            on: graph,
            from: source,
            edgeWeight: weight,
            heuristic: heuristic,
            calculateTotalCost: calculateTotalCost
        )
        .withVisitor { visitor }
        guard let result = sequence.first(where: { $0.currentVertex == destination }) else { return nil }
        return Path(
            source: source,
            destination: destination,
            vertices: result.vertices(to: destination, in: graph),
            edges: result.edges(to: destination, in: graph)
        )
    }
}

extension AStarShortestPathAlgorithm: VisitorSupporting {}

extension ShortestPathAlgorithm {
    static func aStar<Graph: IncidenceGraph, Weight: AdditiveArithmetic, HScore, FScore>(
        weight: CostDefinition<Graph, Weight>,
        heuristic: HeuristicToDestination<Graph, HScore>,
        calculateTotalCost: @escaping (Weight, HScore) -> FScore
    ) -> Self where Self == AStarShortestPathToDestination<Graph, Weight, HScore, FScore> {
        .init(weight: weight, heuristicForDestination: heuristic, calculateTotalCost: calculateTotalCost)
    }

    static func aStar<Graph: IncidenceGraph, Weight: AdditiveArithmetic>(
        weight: CostDefinition<Graph, Weight>,
        heuristic: HeuristicToDestination<Graph, Weight>
    ) -> Self where Self == AStarShortestPathToDestination<Graph, Weight, Weight, Weight> {
        .init(weight: weight, heuristicForDestination: heuristic, calculateTotalCost: +)
    }
}

struct AStarShortestPathToDestination<
    Graph: IncidenceGraph & EdgePropertyGraph,
    Weight: AdditiveArithmetic & Comparable,
    HScore: AdditiveArithmetic,
    FScore: Comparable
>: ShortestPathAlgorithm where
    Graph.VertexDescriptor: Hashable
{
    typealias Visitor = AStar<Graph, Weight, HScore, FScore>.Visitor
    
    let weight: CostDefinition<Graph, Weight>
    let heuristicForDestination: HeuristicToDestination<Graph, HScore>
    let calculateTotalCost: (Weight, HScore) -> FScore

    func shortestPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        let sequence = AStar(
            on: graph,
            from: source,
            edgeWeight: weight,
            heuristic: heuristicForDestination.estimatedCost(destination),
            calculateTotalCost: calculateTotalCost
        )
        .withVisitor { visitor }
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

extension AStarShortestPathToDestination: VisitorSupporting {}
