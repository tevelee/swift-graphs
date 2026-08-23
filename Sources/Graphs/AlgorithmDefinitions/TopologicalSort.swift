extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Performs topological sort using the specified algorithm.
    ///
    /// - Parameter algorithm: The algorithm to use for topological sorting.
    /// - Returns: The topological sort result.
    @inlinable
    public func topologicalSort(
        using algorithm: some TopologicalSortAlgorithm<Self>
    ) -> TopologicalSortResult<VertexDescriptor> {
        algorithm.topologicalSort(in: self, observation: nil)
    }
}

// MARK: - Default Implementations

#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
    extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
        /// Performs topological sort using DFS-based algorithm as the default.
        /// This is the most commonly used and efficient algorithm for topological sorting.
        ///
        /// - Returns: The topological sort result.
        @inlinable
        public func topologicalSort() -> TopologicalSortResult<VertexDescriptor> {
            topologicalSort(using: .dfs())
        }
    }
#endif

/// A protocol for algorithms that perform topological sorting.
public protocol TopologicalSortAlgorithm<Graph>: AlgorithmObserving {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph where Graph.VertexDescriptor: Hashable
    /// The event type published by the algorithm.
    associatedtype Event

    /// Performs topological sort on the graph.
    ///
    /// - Parameters:
    ///   - graph: The graph to sort topologically.
    ///   - observation: An optional algorithm observation.
    /// - Returns: The topological sort result.
    func topologicalSort(
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> TopologicalSortResult<Graph.VertexDescriptor>
}

extension ObservedAlgorithm: TopologicalSortAlgorithm
where Base: TopologicalSortAlgorithm {
    public typealias Graph = Base.Graph

    @inlinable
    public func topologicalSort(
        in graph: Base.Graph,
        observation: AlgorithmObservation<Base.Event>?
    ) -> TopologicalSortResult<Base.Graph.VertexDescriptor> {
        base.topologicalSort(in: graph, observation: self.observation.followed(by: observation))
    }
}

// MARK: - Result Type

/// Represents the result of a topological sort algorithm.
public struct TopologicalSortResult<Vertex: Hashable> {
    /// The topologically sorted vertices.
    public let sortedVertices: [Vertex]

    /// Whether the graph contains a cycle (making topological sort impossible).
    public let hasCycle: Bool

    /// The vertices that are part of a cycle (if any).
    public let cycleVertices: [Vertex]

    /// Creates a new result with the given sorted vertices.
    public init(sortedVertices: [Vertex], hasCycle: Bool = false, cycleVertices: [Vertex] = []) {
        self.sortedVertices = sortedVertices
        self.hasCycle = hasCycle
        self.cycleVertices = cycleVertices
    }

    /// Returns whether the topological sort was successful (no cycles).
    public var isValid: Bool {
        !hasCycle
    }
}

extension TopologicalSortResult: Sendable where Vertex: Sendable {}

extension TopologicalSortResult: Equatable where Vertex: Equatable {
    public static func == (lhs: TopologicalSortResult<Vertex>, rhs: TopologicalSortResult<Vertex>) -> Bool {
        lhs.sortedVertices == rhs.sortedVertices && lhs.hasCycle == rhs.hasCycle && lhs.cycleVertices == rhs.cycleVertices
    }
}

extension TopologicalSortResult: Hashable where Vertex: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(sortedVertices)
        hasher.combine(hasCycle)
        hasher.combine(cycleVertices)
    }
}
