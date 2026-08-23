/// A protocol for algorithms that find all shortest paths with the same minimum cost.
///
/// Unlike k-shortest paths algorithms that return paths with potentially different costs,
/// all-shortest-paths algorithms return only paths that share the optimal (minimum) cost.
/// This is useful when there are multiple equally-optimal paths in a graph.
public protocol AllShortestPathsAlgorithm<Graph, Weight>: AlgorithmObserving {
    /// The type of graph this algorithm operates on.
    associatedtype Graph: IncidenceGraph

    /// The type used for edge weights.
    associatedtype Weight: AdditiveArithmetic & Comparable

    /// The event type published by the algorithm.
    associatedtype Event

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
    ///   - observation: An optional algorithm observation
    /// - Returns: An array of all shortest paths (may be empty if no path exists)
    func allShortestPaths(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> [Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>]
}

/// A protocol for algorithms that find all shortest paths until a condition is met.
///
/// Unlike k-shortest paths algorithms that return paths with potentially different costs,
/// all-shortest-paths algorithms return only paths that share the optimal (minimum) cost.
/// Since condition-based search is strictly more general than point-to-point search,
/// this protocol inherits from ``AllShortestPathsAlgorithm`` and provides a default
/// `from:to:` implementation that delegates to `from:until:`.
public protocol AllShortestPathsUntilAlgorithm<Graph, Weight>: AllShortestPathsAlgorithm {
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
    ///   - observation: An optional algorithm observation
    /// - Returns: An array of all shortest paths (may be empty if no path exists)
    func allShortestPaths(
        from source: Graph.VertexDescriptor,
        until condition: @escaping (Graph.VertexDescriptor) -> Bool,
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> [Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>]
}

// Default implementation: from:to: delegates to until:
extension AllShortestPathsUntilAlgorithm where Graph.VertexDescriptor: Equatable {
    /// Default implementation that delegates to the condition-based search.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - destination: The target vertex
    ///   - graph: The graph to search
    ///   - observation: An optional algorithm observation
    /// - Returns: An array of all shortest paths (may be empty if no path exists)
    @inlinable
    public func allShortestPaths(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph,
        observation: AlgorithmObservation<Event>? = nil
    ) -> [Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>] {
        allShortestPaths(from: source, until: { $0 == destination }, in: graph, observation: observation)
    }
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
        algorithm.allShortestPaths(from: source, until: condition, in: self, observation: nil)
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
        algorithm.allShortestPaths(from: source, to: destination, in: self, observation: nil)
    }
}

// MARK: - Default Implementations

#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
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
#endif

extension ObservedAlgorithm: AllShortestPathsUntilAlgorithm
where Base: AllShortestPathsUntilAlgorithm {
    @inlinable
    public func allShortestPaths(
        from source: Base.Graph.VertexDescriptor,
        until condition: @escaping (Base.Graph.VertexDescriptor) -> Bool,
        in graph: Base.Graph,
        observation: AlgorithmObservation<Base.Event>?
    ) -> [Path<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor>] {
        base.allShortestPaths(from: source, until: condition, in: graph, observation: self.observation.followed(by: observation))
    }
}

extension ObservedAlgorithm: AllShortestPathsAlgorithm
where Base: AllShortestPathsAlgorithm {
    public typealias Weight = Base.Weight

    @inlinable
    public func allShortestPaths(
        from source: Base.Graph.VertexDescriptor,
        to destination: Base.Graph.VertexDescriptor,
        in graph: Base.Graph,
        observation: AlgorithmObservation<Base.Event>?
    ) -> [Path<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor>] {
        base.allShortestPaths(from: source, to: destination, in: graph, observation: self.observation.followed(by: observation))
    }
}
