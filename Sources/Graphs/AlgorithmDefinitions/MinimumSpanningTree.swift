/// A protocol for minimum spanning tree algorithms.
public protocol MinimumSpanningTreeAlgorithm<Graph, Weight> {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph where Graph.VertexDescriptor: Hashable
    /// The weight type for edge costs.
    associatedtype Weight: AdditiveArithmetic & Comparable
    /// The visitor type for observing algorithm progress.
    associatedtype Visitor
    
    /// Computes the minimum spanning tree of the graph.
    ///
    /// - Parameters:
    ///   - graph: The graph to find the MST for
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: The minimum spanning tree result
    func minimumSpanningTree(in graph: Graph, visitor: Visitor?) -> MinimumSpanningTree<Graph.VertexDescriptor, Graph.EdgeDescriptor, Weight>
}

/// Represents the result of a minimum spanning tree computation.
public struct MinimumSpanningTree<Vertex: Hashable, Edge, Weight: AdditiveArithmetic & Comparable> {
    /// The edges in the minimum spanning tree.
    public let edges: [Edge]
    /// The total weight of the minimum spanning tree.
    public let totalWeight: Weight
    /// The vertices in the minimum spanning tree.
    public let vertices: Set<Vertex>
    
    /// Creates a new minimum spanning tree result.
    ///
    /// - Parameters:
    ///   - edges: The edges in the MST
    ///   - totalWeight: The total weight of the MST
    ///   - vertices: The vertices in the MST
    @inlinable
    public init(edges: [Edge], totalWeight: Weight, vertices: Set<Vertex>) {
        self.edges = edges
        self.totalWeight = totalWeight
        self.vertices = vertices
    }
    
    /// Checks if the MST contains a specific vertex.
    ///
    /// - Parameter vertex: The vertex to check
    /// - Returns: True if the vertex is in the MST
    @inlinable
    public func contains(vertex: Vertex) -> Bool {
        vertices.contains(vertex)
    }
    
}

extension MinimumSpanningTree: Sendable where Vertex: Sendable, Edge: Sendable, Weight: Sendable {}

extension MinimumSpanningTree {
    /// The number of edges in the MST.
    @inlinable
    public var edgeCount: Int {
        edges.count
    }
    
    /// The number of vertices in the MST.
    @inlinable
    public var vertexCount: Int {
        vertices.count
    }
}

extension VisitorWrapper: MinimumSpanningTreeAlgorithm where Base: MinimumSpanningTreeAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    public typealias Graph = Base.Graph
    public typealias Weight = Base.Weight
    
    @inlinable
    public func minimumSpanningTree(in graph: Base.Graph, visitor: Base.Visitor?) -> MinimumSpanningTree<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor, Base.Weight> {
        base.minimumSpanningTree(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}

extension IncidenceGraph {
    /// Computes the minimum spanning tree using the specified algorithm.
    ///
    /// - Parameter algorithm: The MST algorithm to use
    /// - Returns: The minimum spanning tree result
    @inlinable
    public func minimumSpanningTree<Weight: AdditiveArithmetic & Comparable>(
        using algorithm: some MinimumSpanningTreeAlgorithm<Self, Weight>
    ) -> MinimumSpanningTree<VertexDescriptor, EdgeDescriptor, Weight> {
        algorithm.minimumSpanningTree(in: self, visitor: nil)
    }
}

// MARK: - Conditional Edge Comparison

extension MinimumSpanningTree where Edge: Equatable {
    /// Checks if the MST contains a specific edge.
    ///
    /// - Parameter edge: The edge to check
    /// - Returns: True if the edge is in the MST
    @inlinable
    public func contains(edge: Edge) -> Bool {
        edges.contains(edge)
    }
}

// MARK: - Default Implementations

extension IncidenceGraph where Self: EdgeListGraph & VertexListGraph, VertexDescriptor: Hashable {
    /// Finds the minimum spanning tree using Kruskal's algorithm as the default.
    /// This is a well-known and efficient algorithm for finding MSTs.
    ///
    /// - Parameter weight: The cost definition for edge weights
    /// - Returns: The minimum spanning tree result
    @inlinable
    public func minimumSpanningTree<Weight: AdditiveArithmetic & Comparable>(
        weight: CostDefinition<Self, Weight>
    ) -> MinimumSpanningTree<VertexDescriptor, EdgeDescriptor, Weight> {
        minimumSpanningTree(using: .kruskal(weight: weight))
    }
}
