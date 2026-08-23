extension Graph where Self: IncidenceGraph, VertexDescriptor: Hashable {
    /// Performs a search using the specified algorithm.
    ///
    /// - Parameters:
    ///   - source: The starting vertex for the search
    ///   - algorithm: The search algorithm to use
    /// - Returns: A sequence of search results
    @inlinable
    public func search<Algorithm: SearchAlgorithm>(
        from source: VertexDescriptor,
        using algorithm: Algorithm
    ) -> Algorithm.SearchSequence where Algorithm.Graph == Self {
        algorithm.search(from: source, in: self, observation: nil)
    }
}

// MARK: - Default Implementations

extension Graph where Self: IncidenceGraph, VertexDescriptor: Hashable {
    /// Performs a depth-first search starting from the specified vertex.
    ///
    /// - Parameter source: The starting vertex for the search
    /// - Returns: A depth-first search sequence
    @inlinable
    public func search(from source: VertexDescriptor) -> DepthFirstSearch<Self> {
        search(from: source, using: .dfs())
    }
}

/// A protocol for graph search algorithms.
///
/// Search algorithms explore a graph in a systematic way, typically looking for
/// specific vertices or paths. This protocol provides a unified interface for
/// different search strategies.
public protocol SearchAlgorithm<Graph>: AlgorithmObserving {
    /// The type of graph this algorithm operates on.
    associatedtype Graph: IncidenceGraph where Graph.VertexDescriptor: Hashable

    /// The type of sequence returned by the search.
    associatedtype SearchSequence: Sequence

    /// The event type published by the algorithm.
    associatedtype Event

    /// Performs a search of the graph starting from the specified vertex.
    ///
    /// - Parameters:
    ///   - source: The starting vertex for the search
    ///   - graph: The graph to search
    ///   - observation: An optional algorithm observation
    /// - Returns: A sequence of search results
    func search(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> SearchSequence
}

extension ObservedAlgorithm: SearchAlgorithm where Base: SearchAlgorithm {
    public typealias Graph = Base.Graph
    public typealias SearchSequence = Base.SearchSequence

    @inlinable
    public func search(
        from source: Base.Graph.VertexDescriptor,
        in graph: Base.Graph,
        observation: AlgorithmObservation<Base.Event>?
    ) -> Base.SearchSequence {
        base.search(from: source, in: graph, observation: self.observation.followed(by: observation))
    }
}
