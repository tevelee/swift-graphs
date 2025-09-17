import Foundation

extension IsomorphismAlgorithm where Graph: IncidenceGraph & VertexListGraph & EdgeListGraph {
    static func vf2<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph>() -> Self where Self == VF2Isomorphism<Graph>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}

extension VF2Isomorphism: IsomorphismAlgorithm {
    func areIsomorphic(_ graph1: Graph, _ graph2: Graph) -> Bool {
        areIsomorphic(graph1, graph2, visitor: nil)
    }
    
    func findIsomorphism(_ graph1: Graph, _ graph2: Graph) -> [Graph.VertexDescriptor: Graph.VertexDescriptor]? {
        findIsomorphism(graph1, graph2, visitor: nil)
    }
}
