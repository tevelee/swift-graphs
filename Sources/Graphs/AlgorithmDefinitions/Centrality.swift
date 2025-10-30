/// A protocol for algorithms that compute vertex centrality measures.
///
/// Centrality algorithms measure the importance or influence of vertices in a graph.
/// Different centrality measures capture different aspects of importance:
/// - **Degree centrality**: Number of connections
/// - **Betweenness centrality**: Position on shortest paths
/// - **Closeness centrality**: Average distance to all other vertices
/// - **Eigenvector centrality**: Importance based on neighbors' importance
/// - **PageRank**: Importance based on link structure
public protocol CentralityAlgorithm<Graph> {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph & VertexListGraph where Graph.VertexDescriptor: Hashable
    /// The visitor type for observing algorithm progress.
    associatedtype Visitor
    
    /// Computes centrality values for all vertices in the graph.
    ///
    /// - Parameters:
    ///   - graph: The graph to compute centrality for.
    ///   - visitor: An optional visitor to observe the algorithm's progress.
    /// - Returns: The centrality values for all vertices.
    func centrality(in graph: Graph, visitor: Visitor?) -> CentralityResult<Graph.VertexDescriptor>
}

extension VisitorWrapper: CentralityAlgorithm where Base: CentralityAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    public typealias Graph = Base.Graph
    
    @inlinable
    public func centrality(in graph: Base.Graph, visitor: Base.Visitor?) -> CentralityResult<Base.Graph.VertexDescriptor> {
        base.centrality(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}

/// Represents the result of a centrality algorithm.
///
/// Contains both raw and normalized centrality values for all vertices in the graph.
/// Normalized values are scaled to the range [0, 1] for easier comparison.
public struct CentralityResult<Vertex: Hashable> {
    /// The raw centrality values for each vertex.
    public let values: [Vertex: Double]
    
    /// The normalized centrality values (0.0 to 1.0).
    ///
    /// Values are normalized using min-max scaling: (value - min) / (max - min).
    /// If all values are equal, normalized values are set to 0.0.
    public let normalizedValues: [Vertex: Double]
    
    /// Creates a new centrality result.
    ///
    /// - Parameter values: The centrality values for each vertex.
    @inlinable
    public init(values: [Vertex: Double]) {
        self.values = values
        
        // Normalize values to [0, 1]
        guard !values.isEmpty else {
            self.normalizedValues = [:]
            return
        }
        
        let allValues = values.values
        let maxValue = allValues.max() ?? 1.0
        let minValue = allValues.min() ?? 0.0
        let range = maxValue - minValue
        
        if range > 0 {
            self.normalizedValues = values.mapValues { ($0 - minValue) / range }
        } else {
            // All values are equal, set normalized to 0.0
            self.normalizedValues = values.mapValues { _ in 0.0 }
        }
    }
    
    /// Gets the centrality value for a specific vertex.
    ///
    /// - Parameter vertex: The vertex to get the centrality for.
    /// - Returns: The centrality value, or 0.0 if not found.
    @inlinable
    public func centrality(for vertex: Vertex) -> Double {
        values[vertex] ?? 0.0
    }
    
    /// Gets the normalized centrality value for a specific vertex.
    ///
    /// - Parameter vertex: The vertex to get the normalized centrality for.
    /// - Returns: The normalized centrality value (0.0 to 1.0), or 0.0 if not found.
    @inlinable
    public func normalizedCentrality(for vertex: Vertex) -> Double {
        normalizedValues[vertex] ?? 0.0
    }
    
    /// Returns vertices sorted by centrality (highest first).
    ///
    /// - Returns: An array of vertices sorted by centrality in descending order.
    @inlinable
    public func verticesByCentrality() -> [Vertex] {
        values.sorted { $0.value > $1.value }.map { $0.key }
    }
    
    /// Returns the vertex with the highest centrality.
    ///
    /// - Returns: The vertex with the highest centrality, or `nil` if the result is empty.
    @inlinable
    public func mostCentralVertex() -> Vertex? {
        values.max(by: { $0.value < $1.value })?.key
    }
}

extension CentralityResult: Sendable where Vertex: Sendable {}

extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Computes centrality using the specified algorithm.
    ///
    /// - Parameter algorithm: The centrality algorithm to use.
    /// - Returns: The centrality result containing values for all vertices.
    @inlinable
    public func centrality(
        using algorithm: some CentralityAlgorithm<Self>
    ) -> CentralityResult<VertexDescriptor> {
        algorithm.centrality(in: self, visitor: nil)
    }
}

// MARK: - Default Implementations

extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Computes degree centrality as the default.
    ///
    /// Degree centrality is the simplest centrality measure, counting the number
    /// of connections each vertex has. This is a fast O(V + E) algorithm suitable
    /// for most initial analyses.
    ///
    /// - Returns: The centrality result using degree centrality.
    @inlinable
    public func centrality() -> CentralityResult<VertexDescriptor> {
        centrality(using: .degree())
    }
}

