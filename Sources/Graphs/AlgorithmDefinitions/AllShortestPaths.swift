/// A protocol for algorithms that find all shortest paths until a condition is met.
///
/// Unlike k-shortest paths algorithms that return paths with potentially different costs,
/// all-shortest-paths algorithms return only paths that share the optimal (minimum) cost.
/// This is useful when there are multiple equally-optimal paths in a graph.
public protocol AllShortestPathsUntilAlgorithm<Graph, Weight> {
    /// The type of graph this algorithm operates on.
    associatedtype Graph: IncidenceGraph
    
    /// The type used for edge weights.
    associatedtype Weight: AdditiveArithmetic & Comparable
    
    /// The type of visitor used for algorithm events.
    associatedtype Visitor
    
    /// Finds all shortest paths from source until a condition is met.
    ///
    /// Returns all paths from source to vertices that satisfy the condition and have the minimum total cost.
    /// If multiple paths exist with the same optimal cost, all are returned.
    /// If no path exists, returns an empty array.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - condition: A closure that determines when to stop searching
    ///   - graph: The graph to search
    ///   - visitor: Optional visitor for algorithm events
    /// - Returns: An array of all shortest paths (may be empty if no path exists)
    func allShortestPaths(
        from source: Graph.VertexDescriptor,
        until condition: @escaping (Graph.VertexDescriptor) -> Bool,
        in graph: Graph,
        visitor: Visitor?
    ) -> [Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>]
}

/// A protocol for algorithms that find all shortest paths with the same minimum cost.
///
/// Unlike k-shortest paths algorithms that return paths with potentially different costs,
/// all-shortest-paths algorithms return only paths that share the optimal (minimum) cost.
/// This is useful when there are multiple equally-optimal paths in a graph.
public protocol AllShortestPathsAlgorithm<Graph, Weight> {
    /// The type of graph this algorithm operates on.
    associatedtype Graph: IncidenceGraph
    
    /// The type used for edge weights.
    associatedtype Weight: AdditiveArithmetic & Comparable
    
    /// The type of visitor used for algorithm events.
    associatedtype Visitor
    
    /// Finds all shortest paths between two vertices.
    ///
    /// Returns all paths from source to destination that have the minimum total cost.
    /// If multiple paths exist with the same optimal cost, all are returned.
    /// If no path exists, returns an empty array.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - destination: The target vertex
    ///   - graph: The graph to search
    ///   - visitor: Optional visitor for algorithm events
    /// - Returns: An array of all shortest paths (may be empty if no path exists)
    func allShortestPaths(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> [Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>]
}

extension IncidenceGraph where VertexDescriptor: Equatable {
    /// Finds all shortest paths from source until a condition is met using the specified algorithm.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - condition: A closure that determines when to stop searching
    ///   - algorithm: The all shortest paths until algorithm to use
    /// - Returns: An array of all paths with the minimum cost
    @inlinable
    public func allShortestPaths<Weight: AdditiveArithmetic & Comparable>(
        from source: VertexDescriptor,
        until condition: @escaping (VertexDescriptor) -> Bool,
        using algorithm: some AllShortestPathsUntilAlgorithm<Self, Weight>
    ) -> [Path<VertexDescriptor, EdgeDescriptor>] {
        algorithm.allShortestPaths(from: source, until: condition, in: self, visitor: nil)
    }
    
    /// Finds all shortest paths between two vertices using the specified algorithm.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - destination: The target vertex
    ///   - algorithm: The all shortest paths algorithm to use
    /// - Returns: An array of all paths with the minimum cost
    @inlinable
    public func allShortestPaths<Weight: AdditiveArithmetic & Comparable>(
        from source: VertexDescriptor,
        to destination: VertexDescriptor,
        using algorithm: some AllShortestPathsAlgorithm<Self, Weight>
    ) -> [Path<VertexDescriptor, EdgeDescriptor>] {
        algorithm.allShortestPaths(from: source, to: destination, in: self, visitor: nil)
    }
}

// MARK: - Default Implementations

extension IncidenceGraph where VertexDescriptor: Hashable {
    /// Finds all shortest paths from source until a condition is met using backtracking Dijkstra's algorithm as the default.
    /// This algorithm finds all paths that have the same minimum cost.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - condition: A closure that determines when to stop searching
    ///   - weight: The cost definition for edge weights
    /// - Returns: An array of all paths with the minimum cost
    @inlinable
    public func allShortestPaths<Weight: Numeric & Comparable>(
        from source: VertexDescriptor,
        until condition: @escaping (VertexDescriptor) -> Bool,
        weight: CostDefinition<Self, Weight>
    ) -> [Path<VertexDescriptor, EdgeDescriptor>] where Weight.Magnitude == Weight {
        allShortestPaths(from: source, until: condition, using: .backtrackingDijkstra(weight: weight))
    }
    
    /// Finds all shortest paths between two vertices using backtracking Dijkstra's algorithm as the default.
    /// This algorithm finds all paths that have the same minimum cost.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - destination: The target vertex
    ///   - weight: The cost definition for edge weights
    /// - Returns: An array of all paths with the minimum cost
    @inlinable
    public func allShortestPaths<Weight: Numeric & Comparable>(
        from source: VertexDescriptor,
        to destination: VertexDescriptor,
        weight: CostDefinition<Self, Weight>
    ) -> [Path<VertexDescriptor, EdgeDescriptor>] where Weight.Magnitude == Weight {
        allShortestPaths(from: source, to: destination, using: .backtrackingDijkstra(weight: weight))
    }
}

extension AllShortestPathsAlgorithm where Self: AllShortestPathsUntilAlgorithm, Graph.VertexDescriptor: Equatable {
    /// Default implementation using the until-based algorithm.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - destination: The target vertex
    ///   - graph: The graph to search
    ///   - visitor: Optional visitor for algorithm events
    /// - Returns: An array of all shortest paths (may be empty if no path exists)
    @inlinable
    public func allShortestPaths(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> [Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>] {
        allShortestPaths(from: source, until: { $0 == destination }, in: graph, visitor: visitor)
    }
}

extension VisitorWrapper: AllShortestPathsUntilAlgorithm where Base: AllShortestPathsUntilAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    public typealias Graph = Base.Graph
    public typealias Weight = Base.Weight
    
    @inlinable
    public func allShortestPaths(
        from source: Base.Graph.VertexDescriptor,
        until condition: @escaping (Base.Graph.VertexDescriptor) -> Bool,
        in graph: Base.Graph,
        visitor: Base.Visitor?
    ) -> [Path<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor>] {
        base.allShortestPaths(from: source, until: condition, in: graph, visitor: self.visitor.combined(with: visitor))
    }
}

extension VisitorWrapper: AllShortestPathsAlgorithm where Base: AllShortestPathsAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    public typealias Graph = Base.Graph
    public typealias Weight = Base.Weight
    
    @inlinable
    public func allShortestPaths(
        from source: Base.Graph.VertexDescriptor,
        to destination: Base.Graph.VertexDescriptor,
        in graph: Base.Graph,
        visitor: Base.Visitor?
    ) -> [Path<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor>] {
        base.allShortestPaths(from: source, to: destination, in: graph, visitor: self.visitor.combined(with: visitor))
    }
}

