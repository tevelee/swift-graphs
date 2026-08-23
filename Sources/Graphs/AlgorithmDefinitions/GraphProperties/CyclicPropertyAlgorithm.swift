extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Checks if the graph is cyclic using the specified algorithm.
    ///
    /// - Parameter algorithm: The cyclic property algorithm to use
    /// - Returns: `true` if the graph is cyclic, `false` otherwise
    @inlinable
    public func isCyclic(
        using algorithm: some CyclicPropertyAlgorithm<Self>
    ) -> Bool {
        algorithm.isCyclic(in: self, observation: nil)
    }
}

// MARK: - Default Implementations

extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Checks if the graph is cyclic using DFS-based algorithm as the default.
    /// This is the most commonly used and efficient algorithm for cycle detection.
    ///
    /// - Returns: `true` if the graph is cyclic, `false` otherwise
    @inlinable
    public func isCyclic() -> Bool {
        isCyclic(using: .dfs())
    }
}

/// A protocol for cyclic property algorithms.
public protocol CyclicPropertyAlgorithm<Graph>: AlgorithmObserving {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph where Graph.VertexDescriptor: Hashable
    /// The event type published by the algorithm.
    associatedtype Event

    /// Checks if the graph is cyclic.
    ///
    /// - Parameters:
    ///   - graph: The graph to check
    ///   - observation: An optional algorithm observation.
    /// - Returns: `true` if the graph is cyclic, `false` otherwise
    @inlinable
    func isCyclic(
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> Bool
}

extension ObservedAlgorithm: CyclicPropertyAlgorithm where Base: CyclicPropertyAlgorithm {
    public typealias Graph = Base.Graph

    @inlinable
    public func isCyclic(in graph: Base.Graph, observation: AlgorithmObservation<Base.Event>?) -> Bool {
        base.isCyclic(in: graph, observation: self.observation.followed(by: observation))
    }
}

extension CyclicPropertyAlgorithm {
    /// Checks cyclicity without observing algorithm events.
    @inlinable
    public func isCyclic(in graph: Graph) -> Bool {
        isCyclic(in: graph, observation: nil)
    }
}
