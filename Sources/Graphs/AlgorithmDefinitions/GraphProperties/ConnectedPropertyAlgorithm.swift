extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Checks if the graph is connected using the specified algorithm.
    ///
    /// - Parameter algorithm: The connected property algorithm to use
    /// - Returns: `true` if the graph is connected, `false` otherwise
    @inlinable
    public func isConnected(
        using algorithm: some ConnectedPropertyAlgorithm<Self>
    ) -> Bool {
        algorithm.isConnected(in: self, observation: nil)
    }
}

// MARK: - Default Implementations

extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Checks if the graph is connected using DFS-based algorithm as the default.
    /// This is the most commonly used and efficient algorithm for connectivity checking.
    ///
    /// - Returns: `true` if the graph is connected, `false` otherwise
    @inlinable
    public func isConnected() -> Bool {
        isConnected(using: .dfs())
    }
}

/// A protocol for connected property algorithms.
public protocol ConnectedPropertyAlgorithm<Graph>: AlgorithmObserving {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph where Graph.VertexDescriptor: Hashable
    /// The event type published by the algorithm.
    associatedtype Event

    /// Checks if the graph is connected.
    ///
    /// - Parameters:
    ///   - graph: The graph to check
    ///   - observation: An optional algorithm observation.
    /// - Returns: `true` if the graph is connected, `false` otherwise
    @inlinable
    func isConnected(
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> Bool
}

extension ObservedAlgorithm: ConnectedPropertyAlgorithm
where Base: ConnectedPropertyAlgorithm {
    public typealias Graph = Base.Graph

    @inlinable
    public func isConnected(in graph: Base.Graph, observation: AlgorithmObservation<Base.Event>?) -> Bool {
        base.isConnected(in: graph, observation: self.observation.followed(by: observation))
    }
}

extension ConnectedPropertyAlgorithm {
    /// Checks connectivity without observing algorithm events.
    @inlinable
    public func isConnected(in graph: Graph) -> Bool {
        isConnected(in: graph, observation: nil)
    }
}
