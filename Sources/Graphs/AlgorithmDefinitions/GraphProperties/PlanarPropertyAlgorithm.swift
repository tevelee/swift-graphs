extension IncidenceGraph where Self: VertexListGraph & EdgeListGraph, VertexDescriptor: Hashable {
    /// Checks if the graph is planar using the specified algorithm.
    ///
    /// - Parameter algorithm: The planar property algorithm to use
    /// - Returns: `true` if the graph is planar, `false` otherwise
    @inlinable
    public func isPlanar(
        using algorithm: some PlanarPropertyAlgorithm<Self>
    ) -> Bool {
        algorithm.isPlanar(in: self, observation: nil)
    }
}

// MARK: - Default Implementations

extension IncidenceGraph where Self: VertexListGraph & EdgeListGraph, VertexDescriptor: Hashable {
    /// Checks if the graph is planar using Boyer-Myrvold algorithm as the default.
    /// This is a well-known and efficient algorithm for planarity testing.
    ///
    /// - Returns: `true` if the graph is planar, `false` otherwise
    @inlinable
    public func isPlanar() -> Bool {
        isPlanar(using: .leftRight())
    }
}

/// A protocol for planar property algorithms.
public protocol PlanarPropertyAlgorithm<Graph>: AlgorithmObserving {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph & EdgeListGraph where Graph.VertexDescriptor: Hashable
    /// The event type published by the algorithm.
    associatedtype Event

    /// Checks if the graph is planar.
    ///
    /// - Parameters:
    ///   - graph: The graph to check
    ///   - observation: An optional algorithm observation.
    /// - Returns: `true` if the graph is planar, `false` otherwise
    @inlinable
    func isPlanar(
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> Bool
}

extension ObservedAlgorithm: PlanarPropertyAlgorithm where Base: PlanarPropertyAlgorithm {
    public typealias Graph = Base.Graph

    @inlinable
    public func isPlanar(in graph: Base.Graph, observation: AlgorithmObservation<Base.Event>?) -> Bool {
        base.isPlanar(in: graph, observation: self.observation.followed(by: observation))
    }
}

extension PlanarPropertyAlgorithm {
    /// Checks planarity without observing algorithm events.
    @inlinable
    public func isPlanar(in graph: Graph) -> Bool {
        isPlanar(in: graph, observation: nil)
    }
}
