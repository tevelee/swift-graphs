extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Finds connected components using the specified algorithm.
    ///
    /// - Parameter algorithm: The connected components algorithm to use
    /// - Returns: The connected components result
    @inlinable
    public func connectedComponents(
        using algorithm: some ConnectedComponentsAlgorithm<Self>
    ) -> ConnectedComponentsResult<VertexDescriptor> {
        algorithm.connectedComponents(in: self, observation: nil)
    }
}

// MARK: - Default Implementations

#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
    extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
        /// Finds connected components using DFS-based algorithm as the default.
        /// This is the most commonly used and efficient algorithm for finding connected components.
        ///
        /// - Returns: The connected components result
        @inlinable
        public func connectedComponents() -> ConnectedComponentsResult<VertexDescriptor> {
            connectedComponents(using: .dfs())
        }
    }
#endif

/// A protocol for connected components algorithms.
public protocol ConnectedComponentsAlgorithm<Graph>: AlgorithmObserving {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph where Graph.VertexDescriptor: Hashable
    /// The event type published by the algorithm.
    associatedtype Event

    /// Finds connected components in the graph.
    ///
    /// - Parameters:
    ///   - graph: The graph to find connected components in
    ///   - observation: An optional algorithm observation.
    /// - Returns: The connected components result
    func connectedComponents(
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> ConnectedComponentsResult<Graph.VertexDescriptor>
}

extension ObservedAlgorithm: ConnectedComponentsAlgorithm
where Base: ConnectedComponentsAlgorithm {
    public typealias Graph = Base.Graph

    @inlinable
    public func connectedComponents(
        in graph: Base.Graph,
        observation: AlgorithmObservation<Base.Event>?
    ) -> ConnectedComponentsResult<Base.Graph.VertexDescriptor> {
        base.connectedComponents(in: graph, observation: self.observation.followed(by: observation))
    }
}

// MARK: - Result Type

/// Represents the result of a connected components algorithm.
public struct ConnectedComponentsResult<Vertex: Hashable> {
    /// The connected components, where each inner array represents one component.
    public let components: [[Vertex]]

    /// A mapping from each vertex to its component index.
    public let vertexToComponent: [Vertex: Int]

    /// The number of connected components.
    public var componentCount: Int {
        components.count
    }

    /// Creates a new result with the given components.
    public init(components: [[Vertex]]) {
        self.components = components
        var mapping: [Vertex: Int] = [:]
        for (componentIndex, component) in components.enumerated() {
            for vertex in component {
                mapping[vertex] = componentIndex
            }
        }
        self.vertexToComponent = mapping
    }

    /// Returns the component index for the given vertex.
    public func componentIndex(for vertex: Vertex) -> Int? {
        vertexToComponent[vertex]
    }

    /// Returns the component containing the given vertex.
    public func component(containing vertex: Vertex) -> [Vertex]? {
        guard let index = componentIndex(for: vertex) else { return nil }
        return components[index]
    }
}

extension ConnectedComponentsResult: Sendable where Vertex: Sendable {}

extension ConnectedComponentsResult {
    /// Returns whether two vertices are in the same connected component.
    public func areInSameComponent(_ vertex1: Vertex, _ vertex2: Vertex) -> Bool {
        guard let index1 = componentIndex(for: vertex1),
            let index2 = componentIndex(for: vertex2)
        else { return false }
        return index1 == index2
    }
}

extension ConnectedComponentsResult: Equatable where Vertex: Equatable {
    public static func == (lhs: ConnectedComponentsResult<Vertex>, rhs: ConnectedComponentsResult<Vertex>) -> Bool {
        lhs.vertexToComponent == rhs.vertexToComponent
    }
}

extension ConnectedComponentsResult: Hashable where Vertex: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(vertexToComponent)
    }
}

extension ConnectedComponentsAlgorithm {
    /// Finds connected components without observing algorithm events.
    @inlinable
    public func connectedComponents(in graph: Graph) -> ConnectedComponentsResult<Graph.VertexDescriptor> {
        connectedComponents(in: graph, observation: nil)
    }
}
