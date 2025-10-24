extension ShortestPathUntilAlgorithm {
    /// Creates an A* shortest path until algorithm with custom cost calculation.
    ///
    /// - Parameters:
    ///   - weight: The cost definition for edge weights
    ///   - heuristic: The heuristic function for estimating remaining cost
    ///   - calculateTotalCost: A function to combine g-score and h-score
    /// - Returns: An A* shortest path until algorithm
    @inlinable
    public static func aStar<Graph: IncidenceGraph, Weight: AdditiveArithmetic, HScore, FScore>(
        weight: CostDefinition<Graph, Weight>,
        heuristic: Heuristic<Graph, HScore>,
        calculateTotalCost: @escaping (Weight, HScore) -> FScore
    ) -> Self where Self == AStarShortestPathUntil<Graph, Weight, HScore, FScore> {
        .init(weight: weight, heuristic: heuristic, calculateTotalCost: calculateTotalCost)
    }
    
    /// Creates an A* shortest path until algorithm with simple addition for cost calculation.
    ///
    /// - Parameters:
    ///   - weight: The cost definition for edge weights
    ///   - heuristic: The heuristic function for estimating remaining cost
    /// - Returns: An A* shortest path until algorithm
    @inlinable
    public static func aStar<Graph: IncidenceGraph, Weight: AdditiveArithmetic>(
        weight: CostDefinition<Graph, Weight>,
        heuristic: Heuristic<Graph, Weight>
    ) -> Self where Self == AStarShortestPathUntil<Graph, Weight, Weight, Weight> {
        .init(weight: weight, heuristic: heuristic, calculateTotalCost: +)
    }
}

/// An A* shortest path until algorithm implementation for the ShortestPathUntilAlgorithm protocol.
///
/// This struct wraps the core A* algorithm to provide a ShortestPathUntilAlgorithm interface,
/// making it easy to use A* for finding shortest paths until a condition is met.
///
/// - Complexity: O((V + E) log V) where V is the number of vertices and E is the number of edges
public struct AStarShortestPathUntil<
    Graph: IncidenceGraph,
    Weight: AdditiveArithmetic & Comparable,
    HScore: AdditiveArithmetic,
    FScore: Comparable
>: ShortestPathUntilAlgorithm where
    Graph.VertexDescriptor: Hashable
{
    /// The cost definition for edge weights.
    public let weight: CostDefinition<Graph, Weight>
    /// The heuristic function for estimating remaining cost.
    public let heuristic: Heuristic<Graph, HScore>
    /// The function to combine g-score and h-score.
    public let calculateTotalCost: (Weight, HScore) -> FScore

    /// Creates a new A* shortest path until algorithm.
    ///
    /// - Parameters:
    ///   - weight: The cost definition for edge weights
    ///   - heuristic: The heuristic function for estimating remaining cost
    ///   - calculateTotalCost: A function to combine g-score and h-score
    @inlinable
    public init(
        weight: CostDefinition<Graph, Weight>,
        heuristic: Heuristic<Graph, HScore>,
        calculateTotalCost: @escaping (Weight, HScore) -> FScore
    ) {
        self.weight = weight
        self.heuristic = heuristic
        self.calculateTotalCost = calculateTotalCost
    }
    
    /// Finds the shortest path from source until a condition is met using A*.
    ///
    /// - Parameters:
    ///   - source: The source vertex
    ///   - condition: The condition that determines when to stop
    ///   - graph: The graph to search in
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: The shortest path to the first vertex that satisfies the condition, if one exists
    @inlinable
    public func shortestPath(
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

