extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Checks if the graph is bipartite using the specified algorithm.
    ///
    /// - Parameter algorithm: The bipartite property algorithm to use
    /// - Returns: `true` if the graph is bipartite, `false` otherwise
    @inlinable
    public func isBipartite(
        using algorithm: some BipartitePropertyAlgorithm<Self>
    ) -> Bool {
        algorithm.isBipartite(in: self, observation: nil)
    }
}

// MARK: - Default Implementations

extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Checks if the graph is bipartite using DFS-based algorithm as the default.
    /// This is the most commonly used and efficient algorithm for bipartiteness checking.
    ///
    /// - Returns: `true` if the graph is bipartite, `false` otherwise
    @inlinable
    public func isBipartite() -> Bool {
        isBipartite(using: .dfs())
    }
}

/// A protocol for bipartite property algorithms.
public protocol BipartitePropertyAlgorithm<Graph>: AlgorithmObserving {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph where Graph.VertexDescriptor: Hashable
    /// The event type published by the algorithm.
    associatedtype Event

    /// Checks if the graph is bipartite.
    ///
    /// - Parameters:
    ///   - graph: The graph to check
    ///   - observation: An optional algorithm observation.
    /// - Returns: `true` if the graph is bipartite, `false` otherwise
    @inlinable
    func isBipartite(
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> Bool
}

extension ObservedAlgorithm: BipartitePropertyAlgorithm
where Base: BipartitePropertyAlgorithm {
    public typealias Graph = Base.Graph

    @inlinable
    public func isBipartite(in graph: Base.Graph, observation: AlgorithmObservation<Base.Event>?) -> Bool {
        base.isBipartite(in: graph, observation: self.observation.followed(by: observation))
    }
}
