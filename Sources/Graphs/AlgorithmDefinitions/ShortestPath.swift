extension IncidenceGraph where VertexDescriptor: Equatable {
    /// Finds the shortest path between two vertices using the specified algorithm.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - destination: The target vertex
    ///   - algorithm: The shortest path algorithm to use
    /// - Returns: The shortest path, or `nil` if no path exists
    @inlinable
    public func shortestPath(
        from source: VertexDescriptor,
        to destination: VertexDescriptor,
        using algorithm: some ShortestPathAlgorithm<Self>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.shortestPath(from: source, to: destination, in: self, observation: nil)
    }
}

// MARK: - Default Implementations

#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    extension IncidenceGraph where VertexDescriptor: Hashable {
        /// Finds the shortest path between two vertices using Dijkstra's algorithm as the default.
        /// This is the most commonly used and efficient algorithm for non-negative edge weights.
        ///
        /// - Important: All edge weights must be non-negative. For graphs with negative edge weights,
        ///   use `.bellmanFord` or `.spfa` instead; passing negative weights here produces incorrect results.
        ///
        /// - Parameters:
        ///   - source: The starting vertex
        ///   - destination: The target vertex
        ///   - weight: The cost definition for edge weights
        /// - Returns: The shortest path, or `nil` if no path exists
        @inlinable
        public func shortestPath<Weight: Numeric & Comparable>(
            from source: VertexDescriptor,
            to destination: VertexDescriptor,
            weight: CostDefinition<Self, Weight>
        ) -> Path<VertexDescriptor, EdgeDescriptor>? where Weight.Magnitude == Weight {
            shortestPath(from: source, to: destination, using: .dijkstra(weight: weight))
        }
    }
#endif

/// A protocol for shortest path algorithms.
///
/// Shortest path algorithms find the path with minimum total weight between two vertices
/// in a weighted graph. Different algorithms have different characteristics and requirements.
public protocol ShortestPathAlgorithm<Graph>: AlgorithmObserving {
    /// The type of graph this algorithm operates on.
    associatedtype Graph: IncidenceGraph

    /// The event type published by the algorithm.
    associatedtype Event

    /// Finds the shortest path between two vertices.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - destination: The target vertex
    ///   - graph: The graph to search
    ///   - observation: An optional algorithm observation
    /// - Returns: The shortest path, or `nil` if no path exists
    func shortestPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
}

extension ObservedAlgorithm: ShortestPathAlgorithm where Base: ShortestPathAlgorithm {
    public typealias Graph = Base.Graph

    @inlinable
    public func shortestPath(
        from source: Base.Graph.VertexDescriptor,
        to destination: Base.Graph.VertexDescriptor,
        in graph: Base.Graph,
        observation: AlgorithmObservation<Base.Event>?
    ) -> Path<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor>? {
        base.shortestPath(from: source, to: destination, in: graph, observation: self.observation.followed(by: observation))
    }
}

extension ShortestPathAlgorithm {
    /// Finds a shortest path without observing algorithm events.
    @inlinable
    public func shortestPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        shortestPath(from: source, to: destination, in: graph, observation: nil)
    }
}
