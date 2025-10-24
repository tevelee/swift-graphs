extension SearchAlgorithm {
    /// Creates an A* search algorithm with custom cost calculation.
    ///
    /// - Parameters:
    ///   - edgeWeight: The cost definition for edge weights
    ///   - heuristic: The heuristic function for estimating remaining cost
    ///   - calculateTotalCost: A function to combine g-score and h-score
    /// - Returns: An A* search algorithm
    @inlinable
    public static func aStar<Graph, Weight, HScore, FScore>(
        edgeWeight: CostDefinition<Graph, Weight>,
        heuristic: Heuristic<Graph, HScore>,
        calculateTotalCost: @escaping (Weight, HScore) -> FScore
    ) -> Self where Self == AStarSearch<Graph, Weight, HScore, FScore> {
        .init(edgeWeight: edgeWeight, heuristic: heuristic, calculateTotalCost: calculateTotalCost)
    }
    
    /// Creates an A* search algorithm with simple addition for cost calculation.
    ///
    /// - Parameters:
    ///   - edgeWeight: The cost definition for edge weights
    ///   - heuristic: The heuristic function for estimating remaining cost
    /// - Returns: An A* search algorithm
    @inlinable
    public static func aStar<Graph, Weight>(
        edgeWeight: CostDefinition<Graph, Weight>,
        heuristic: Heuristic<Graph, Weight>
    ) -> Self where Self == AStarSearch<Graph, Weight, Weight, Weight> {
        .init(edgeWeight: edgeWeight, heuristic: heuristic, calculateTotalCost: +)
    }
}

/// An A* search algorithm implementation for the SearchAlgorithm protocol.
///
/// This struct wraps the core A* algorithm to provide a SearchAlgorithm interface,
/// making it easy to use A* as a general search algorithm.
public struct AStarSearch<
    Graph: IncidenceGraph,
    Weight: AdditiveArithmetic & Comparable,
    HScore: AdditiveArithmetic,
    FScore: Comparable
>: SearchAlgorithm where Graph.VertexDescriptor: Hashable {
    public typealias Visitor = AStar<Graph, Weight, HScore, FScore>.Visitor
    
    public let edgeWeight: CostDefinition<Graph, Weight>
    public let heuristic: Heuristic<Graph, HScore>
    public let calculateTotalCost: (Weight, HScore) -> FScore
    
    @inlinable
    public init(
        edgeWeight: CostDefinition<Graph, Weight>,
        heuristic: Heuristic<Graph, HScore>,
        calculateTotalCost: @escaping (Weight, HScore) -> FScore
    ) {
        self.edgeWeight = edgeWeight
        self.heuristic = heuristic
        self.calculateTotalCost = calculateTotalCost
    }
    
    @inlinable
    public func search(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
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

extension AStarSearch: VisitorSupporting {}
