extension IncidenceGraph where Self: VertexListGraph & EdgeListGraph, VertexDescriptor: Hashable {
    /// Checks if the graph is a tree using the specified algorithm.
    ///
    /// - Parameter algorithm: The tree property algorithm to use
    /// - Returns: `true` if the graph is a tree, `false` otherwise
    @inlinable
    public func isTree(
        using algorithm: some TreePropertyAlgorithm<Self>
    ) -> Bool {
        algorithm.isTree(in: self, observation: nil)
    }
}

// MARK: - Default Implementations

extension IncidenceGraph where Self: VertexListGraph & EdgeListGraph, VertexDescriptor: Hashable {
    /// Checks if the graph is a tree using DFS-based algorithm as the default.
    /// A graph is a tree if it's connected and has no cycles.
    ///
    /// - Returns: `true` if the graph is a tree, `false` otherwise
    @inlinable
    public func isTree() -> Bool {
        isTree(using: .dfs())
    }
}

/// A protocol for tree property algorithms.
public protocol TreePropertyAlgorithm<Graph>: AlgorithmObserving {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph & EdgeListGraph where Graph.VertexDescriptor: Hashable
    /// The event type published by the algorithm.
    associatedtype Event

    /// Checks if the graph is a tree.
    ///
    /// - Parameters:
    ///   - graph: The graph to check
    ///   - observation: An optional algorithm observation.
    /// - Returns: `true` if the graph is a tree, `false` otherwise
    @inlinable
    func isTree(
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> Bool
}

extension ObservedAlgorithm: TreePropertyAlgorithm where Base: TreePropertyAlgorithm {
    public typealias Graph = Base.Graph

    @inlinable
    public func isTree(in graph: Base.Graph, observation: AlgorithmObservation<Base.Event>?) -> Bool {
        base.isTree(in: graph, observation: self.observation.followed(by: observation))
    }
}

extension TreePropertyAlgorithm {
    /// Checks whether a graph is a tree without observing algorithm events.
    @inlinable
    public func isTree(in graph: Graph) -> Bool {
        isTree(in: graph, observation: nil)
    }
}
