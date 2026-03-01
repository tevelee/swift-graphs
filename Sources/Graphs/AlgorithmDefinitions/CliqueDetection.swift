extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Finds maximal cliques using the specified algorithm.
    ///
    /// - Parameter algorithm: The clique detection algorithm to use
    /// - Returns: The clique detection result
    @inlinable
    public func findCliques(
        using algorithm: some CliqueDetectionAlgorithm<Self>
    ) -> CliqueDetectionResult<VertexDescriptor> {
        algorithm.findCliques(in: self, visitor: nil)
    }
}

// MARK: - Default Implementations

#if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Finds maximal cliques using Bron-Kerbosch algorithm as the default.
    /// This is the most commonly used algorithm for clique detection.
    ///
    /// - Returns: The clique detection result
    @inlinable
    public func findCliques() -> CliqueDetectionResult<VertexDescriptor> {
        findCliques(using: .bronKerbosch())
    }
}
#endif

/// A protocol for clique detection algorithms.
public protocol CliqueDetectionAlgorithm<Graph> {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph & VertexListGraph where Graph.VertexDescriptor: Hashable
    /// The visitor type for observing algorithm progress.
    associatedtype Visitor

    /// Finds maximal cliques in the graph.
    ///
    /// - Parameters:
    ///   - graph: The graph to find cliques in
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: The clique detection result
    func findCliques(
        in graph: Graph,
        visitor: Visitor?
    ) -> CliqueDetectionResult<Graph.VertexDescriptor>
}

extension VisitorWrapper: CliqueDetectionAlgorithm 
    where Base: CliqueDetectionAlgorithm, 
          Base.Visitor == Visitor, 
          Visitor: Composable, 
          Visitor.Other == Visitor 
{
    public typealias Graph = Base.Graph
    
    @inlinable
    public func findCliques(
        in graph: Base.Graph,
        visitor: Base.Visitor?
    ) -> CliqueDetectionResult<Base.Graph.VertexDescriptor> {
        base.findCliques(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}

// MARK: - Result Type

/// Represents the result of a clique detection algorithm.
public struct CliqueDetectionResult<Vertex: Hashable> {
    /// The maximal cliques, where each inner array represents one clique.
    public let cliques: [[Vertex]]
    
    /// The largest clique size.
    public var maximalCliqueSize: Int {
        cliques.map { $0.count }.max() ?? 0
    }
    
    /// The number of maximal cliques.
    public var cliqueCount: Int {
        cliques.count
    }
    
    /// Creates a new result with the given cliques.
    public init(cliques: [[Vertex]]) {
        self.cliques = cliques
    }
    
    /// Returns all cliques of a given size.
    public func cliques(ofSize size: Int) -> [[Vertex]] {
        cliques.filter { $0.count == size }
    }
    
    /// Returns whether a set of vertices forms a clique.
    public func isClique(_ vertices: Set<Vertex>) -> Bool {
        cliques.contains { Set($0) == vertices }
    }
    
    /// Returns all cliques containing the given vertex.
    public func cliques(containing vertex: Vertex) -> [[Vertex]] {
        cliques.filter { $0.contains(vertex) }
    }
}

extension CliqueDetectionResult: Sendable where Vertex: Sendable {}

extension CliqueDetectionResult: Equatable where Vertex: Equatable {
    public static func == (lhs: CliqueDetectionResult<Vertex>, rhs: CliqueDetectionResult<Vertex>) -> Bool {
        lhs.cliques.count == rhs.cliques.count && 
        Set(lhs.cliques.map { Set($0) }) == Set(rhs.cliques.map { Set($0) })
    }
}

extension CliqueDetectionResult: Hashable where Vertex: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(Set(cliques.map { Set($0) }))
    }
}
