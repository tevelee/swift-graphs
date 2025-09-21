import Foundation

protocol MinimumSpanningTreeAlgorithm<Graph, Weight> {
    associatedtype Graph: IncidenceGraph & EdgePropertyGraph where Graph.VertexDescriptor: Hashable
    associatedtype Weight: AdditiveArithmetic & Comparable
    associatedtype Visitor
    
    func minimumSpanningTree(in graph: Graph, visitor: Visitor?) -> MinimumSpanningTree<Graph.VertexDescriptor, Graph.EdgeDescriptor, Weight>
}

struct MinimumSpanningTree<Vertex: Hashable, Edge, Weight: AdditiveArithmetic & Comparable> {
    let edges: [Edge]
    let totalWeight: Weight
    let vertices: Set<Vertex>
    
    init(edges: [Edge], totalWeight: Weight, vertices: Set<Vertex>) {
        self.edges = edges
        self.totalWeight = totalWeight
        self.vertices = vertices
    }
    
    func contains(vertex: Vertex) -> Bool {
        vertices.contains(vertex)
    }
    
    func contains(edge: Edge) -> Bool {
        edges.contains { $0 as? AnyHashable == edge as? AnyHashable }
    }
    
    var edgeCount: Int {
        edges.count
    }
    
    var vertexCount: Int {
        vertices.count
    }
}

extension VisitorWrapper: MinimumSpanningTreeAlgorithm where Base: MinimumSpanningTreeAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    typealias Graph = Base.Graph
    typealias Weight = Base.Weight
    
    func minimumSpanningTree(in graph: Base.Graph, visitor: Base.Visitor?) -> MinimumSpanningTree<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor, Base.Weight> {
        base.minimumSpanningTree(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}

extension IncidenceGraph where Self: EdgePropertyGraph {
    func minimumSpanningTree<Weight: AdditiveArithmetic & Comparable>(
        using algorithm: some MinimumSpanningTreeAlgorithm<Self, Weight>
    ) -> MinimumSpanningTree<VertexDescriptor, EdgeDescriptor, Weight> {
        algorithm.minimumSpanningTree(in: self, visitor: nil)
    }
}

// MARK: - Default Implementations

extension IncidenceGraph where Self: EdgePropertyGraph & EdgeListGraph & VertexListGraph, VertexDescriptor: Hashable {
    /// Finds the minimum spanning tree using Kruskal's algorithm as the default.
    /// This is a well-known and efficient algorithm for finding MSTs.
    func minimumSpanningTree<Weight: AdditiveArithmetic & Comparable>(
        weight: CostDefinition<Self, Weight>
    ) -> MinimumSpanningTree<VertexDescriptor, EdgeDescriptor, Weight> {
        minimumSpanningTree(using: .kruskal(weight: weight))
    }
}
