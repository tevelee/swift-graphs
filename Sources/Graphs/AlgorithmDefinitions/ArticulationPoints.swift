extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable, EdgeDescriptor: Hashable {
    /// Finds articulation points (cut vertices) and bridges (cut edges) using the specified algorithm.
    ///
    /// - Parameter algorithm: The articulation points algorithm to use
    /// - Returns: The articulation points result containing cut vertices and bridges
    @inlinable
    public func articulationPoints(
        using algorithm: some ArticulationPointsAlgorithm<Self>
    ) -> ArticulationPointsResult<VertexDescriptor, EdgeDescriptor> {
        algorithm.articulationPoints(in: self, observation: nil)
    }

    #if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
        /// Finds articulation points (cut vertices) and bridges (cut edges) using Tarjan's algorithm as the default.
        ///
        /// - Returns: The articulation points result containing cut vertices and bridges
        @inlinable
        public func articulationPoints() -> ArticulationPointsResult<VertexDescriptor, EdgeDescriptor> {
            articulationPoints(using: .tarjan())
        }
    #endif
}

/// A protocol for articulation points algorithms.
public protocol ArticulationPointsAlgorithm<Graph>: AlgorithmObserving {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph where Graph.VertexDescriptor: Hashable, Graph.EdgeDescriptor: Hashable
    /// The event type published by the algorithm.
    associatedtype Event

    /// Finds articulation points and bridges in the graph.
    ///
    /// - Parameters:
    ///   - graph: The graph to analyze
    ///   - observation: An optional algorithm observation.
    /// - Returns: The articulation points result
    func articulationPoints(
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> ArticulationPointsResult<Graph.VertexDescriptor, Graph.EdgeDescriptor>
}

extension ObservedAlgorithm: ArticulationPointsAlgorithm
where Base: ArticulationPointsAlgorithm {
    public typealias Graph = Base.Graph

    @inlinable
    public func articulationPoints(
        in graph: Base.Graph,
        observation: AlgorithmObservation<Base.Event>?
    ) -> ArticulationPointsResult<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor> {
        base.articulationPoints(in: graph, observation: self.observation.followed(by: observation))
    }
}

// MARK: - Result Type

/// Represents the result of an articulation points algorithm.
public struct ArticulationPointsResult<Vertex: Hashable, Edge: Hashable> {
    /// The set of cut vertices (articulation points) in the graph.
    public let cutVertices: Set<Vertex>

    /// The bridge edges (cut edges) in the graph.
    public let bridges: [Edge]

    /// A set of bridge edges for efficient lookup.
    @usableFromInline
    let bridgeSet: Set<Edge>

    /// Creates a new result with the given cut vertices and bridges.
    public init(cutVertices: Set<Vertex>, bridges: [Edge]) {
        self.cutVertices = cutVertices
        self.bridges = bridges
        self.bridgeSet = Set(bridges)
    }

    /// Returns whether the given vertex is an articulation point.
    @inlinable
    public func isArticulationPoint(_ vertex: Vertex) -> Bool {
        cutVertices.contains(vertex)
    }

    /// Returns whether the given edge is a bridge.
    @inlinable
    public func isBridge(_ edge: Edge) -> Bool {
        bridgeSet.contains(edge)
    }
}

extension ArticulationPointsResult: Sendable where Vertex: Sendable, Edge: Sendable {}

extension ArticulationPointsResult: Equatable where Vertex: Equatable, Edge: Equatable {
    public static func == (lhs: ArticulationPointsResult, rhs: ArticulationPointsResult) -> Bool {
        lhs.cutVertices == rhs.cutVertices && lhs.bridgeSet == rhs.bridgeSet
    }
}
