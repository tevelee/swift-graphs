import Foundation

extension BipartitePropertyAlgorithm {
    static func bfs<Graph: IncidenceGraph & VertexListGraph>() -> Self where Self == BFSBipartitePropertyAlgorithm<Graph>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}

extension BFSBipartitePropertyAlgorithm: BipartitePropertyAlgorithm {}
