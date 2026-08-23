extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Detects communities using the specified algorithm.
    ///
    /// - Parameter algorithm: The community detection algorithm to use
    /// - Returns: The community detection result
    @inlinable
    public func detectCommunities(
        using algorithm: some CommunityDetectionAlgorithm<Self>
    ) -> CommunityDetectionResult<VertexDescriptor> {
        algorithm.detectCommunities(in: self, observation: nil)
    }
}

// MARK: - Default Implementations

#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
    extension IncidenceGraph where Self: VertexListGraph & EdgeListGraph, VertexDescriptor: Hashable {
        /// Detects communities using Louvain algorithm as the default.
        /// This is a fast and widely-used algorithm for community detection.
        ///
        /// - Returns: The community detection result
        @inlinable
        public func detectCommunities() -> CommunityDetectionResult<VertexDescriptor> {
            detectCommunities(using: .louvain())
        }
    }
#endif

/// A protocol for community detection algorithms.
public protocol CommunityDetectionAlgorithm<Graph>: AlgorithmObserving {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph & VertexListGraph where Graph.VertexDescriptor: Hashable
    /// The event type published by the algorithm.
    associatedtype Event

    /// Detects communities in the graph.
    ///
    /// - Parameters:
    ///   - graph: The graph to detect communities in
    ///   - observation: An optional algorithm observation.
    /// - Returns: The community detection result
    func detectCommunities(
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> CommunityDetectionResult<Graph.VertexDescriptor>
}

extension ObservedAlgorithm: CommunityDetectionAlgorithm where Base: CommunityDetectionAlgorithm {
    public typealias Graph = Base.Graph

    @inlinable
    public func detectCommunities(
        in graph: Base.Graph,
        observation: AlgorithmObservation<Base.Event>?
    ) -> CommunityDetectionResult<Base.Graph.VertexDescriptor> {
        base.detectCommunities(in: graph, observation: self.observation.followed(by: observation))
    }
}

// MARK: - Result Type

/// Represents the result of a community detection algorithm.
public struct CommunityDetectionResult<Vertex: Hashable> {
    /// The communities, where each inner array represents one community.
    public let communities: [[Vertex]]

    /// A mapping from each vertex to its community index.
    public let vertexToCommunity: [Vertex: Int]

    /// The modularity score of the detected communities.
    public let modularity: Double

    /// The number of communities.
    public var communityCount: Int {
        communities.count
    }

    /// Creates a new result with the given communities.
    public init(communities: [[Vertex]], modularity: Double = 0.0) {
        self.communities = communities
        self.modularity = modularity
        var mapping: [Vertex: Int] = [:]
        for (communityIndex, community) in communities.enumerated() {
            for vertex in community {
                mapping[vertex] = communityIndex
            }
        }
        self.vertexToCommunity = mapping
    }

    /// Returns the community index for the given vertex.
    public func communityIndex(for vertex: Vertex) -> Int? {
        vertexToCommunity[vertex]
    }

    /// Returns the community containing the given vertex.
    public func community(containing vertex: Vertex) -> [Vertex]? {
        guard let index = communityIndex(for: vertex) else { return nil }
        return communities[index]
    }

    /// Returns whether two vertices are in the same community.
    public func areInSameCommunity(_ vertex1: Vertex, _ vertex2: Vertex) -> Bool {
        guard let index1 = communityIndex(for: vertex1),
            let index2 = communityIndex(for: vertex2)
        else { return false }
        return index1 == index2
    }
}

extension CommunityDetectionResult: Sendable where Vertex: Sendable {}

extension CommunityDetectionResult: Equatable where Vertex: Equatable {
    public static func == (lhs: CommunityDetectionResult<Vertex>, rhs: CommunityDetectionResult<Vertex>) -> Bool {
        lhs.vertexToCommunity == rhs.vertexToCommunity && abs(lhs.modularity - rhs.modularity) < 1e-9
    }
}

extension CommunityDetectionResult: Hashable where Vertex: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(vertexToCommunity)
        hasher.combine(modularity)
    }
}
