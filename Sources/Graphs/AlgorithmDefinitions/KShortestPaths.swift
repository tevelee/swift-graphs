/// A protocol for algorithms that find k shortest paths.
public protocol KShortestPathsAlgorithm<Graph, Weight>: AlgorithmObserving {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph
    /// The weight type for edge costs.
    associatedtype Weight: AdditiveArithmetic & Comparable
    /// The event type published by the algorithm.
    associatedtype Event

    /// Finds the k shortest paths from source to destination.
    ///
    /// - Parameters:
    ///   - source: The source vertex
    ///   - destination: The destination vertex
    ///   - k: The number of shortest paths to find
    ///   - graph: The graph to search in
    ///   - observation: An optional algorithm observation.
    /// - Returns: An array of the k shortest paths, ordered by cost
    func kShortestPaths(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        k: Int,
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> [Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>]
}

extension IncidenceGraph where VertexDescriptor: Equatable {
    public func kShortestPaths<Weight: AdditiveArithmetic & Comparable>(
        from source: VertexDescriptor,
        to destination: VertexDescriptor,
        k: Int,
        using algorithm: some KShortestPathsAlgorithm<Self, Weight>
    ) -> [Path<VertexDescriptor, EdgeDescriptor>] {
        algorithm.kShortestPaths(from: source, to: destination, k: k, in: self, observation: nil)
    }
}

// MARK: - Default Implementations

#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    extension IncidenceGraph where VertexDescriptor: Hashable, EdgeDescriptor: Hashable {
        /// Finds the k shortest paths using Yen's algorithm as the default.
        /// This is the most commonly used algorithm for finding k shortest paths.
        public func kShortestPaths<Weight: Numeric & Comparable>(
            from source: VertexDescriptor,
            to destination: VertexDescriptor,
            k: Int,
            weight: CostDefinition<Self, Weight>
        ) -> [Path<VertexDescriptor, EdgeDescriptor>] where Weight.Magnitude == Weight {
            kShortestPaths(from: source, to: destination, k: k, using: .yen(weight: weight))
        }
    }
#endif

extension ObservedAlgorithm: KShortestPathsAlgorithm where Base: KShortestPathsAlgorithm {
    public typealias Graph = Base.Graph
    public typealias Weight = Base.Weight

    @inlinable
    public func kShortestPaths(
        from source: Base.Graph.VertexDescriptor,
        to destination: Base.Graph.VertexDescriptor,
        k: Int,
        in graph: Base.Graph,
        observation: AlgorithmObservation<Base.Event>?
    ) -> [Path<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor>] {
        base.kShortestPaths(from: source, to: destination, k: k, in: graph, observation: self.observation.followed(by: observation))
    }
}

extension KShortestPathsAlgorithm {
    /// Finds the k shortest paths without observing algorithm events.
    @inlinable
    public func kShortestPaths(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        k: Int,
        in graph: Graph
    ) -> [Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>] {
        kShortestPaths(from: source, to: destination, k: k, in: graph, observation: nil)
    }
}
