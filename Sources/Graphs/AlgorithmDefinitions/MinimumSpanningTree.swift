import Foundation

protocol MinimumSpanningTreeAlgorithm<Graph, Weight> {
    associatedtype Graph: IncidenceGraph & EdgePropertyGraph where Graph.VertexDescriptor: Hashable
    associatedtype Weight: AdditiveArithmetic & Comparable
    
    func minimumSpanningTree(in graph: Graph) -> MinimumSpanningTree<Graph.VertexDescriptor, Graph.EdgeDescriptor, Weight>
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

extension IncidenceGraph where Self: EdgePropertyGraph {
    func minimumSpanningTree<Weight: AdditiveArithmetic & Comparable>(
        using algorithm: some MinimumSpanningTreeAlgorithm<Self, Weight>
    ) -> MinimumSpanningTree<VertexDescriptor, EdgeDescriptor, Weight> {
        algorithm.minimumSpanningTree(in: self)
    }
}
