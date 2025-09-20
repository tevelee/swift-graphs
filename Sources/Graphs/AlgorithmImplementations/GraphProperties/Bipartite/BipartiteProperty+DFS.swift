import Foundation

extension BipartitePropertyAlgorithm {
    static func dfs<Graph: IncidenceGraph & VertexListGraph>() -> Self where Self == DFSBipartitePropertyAlgorithm<Graph>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}

extension DFSBipartitePropertyAlgorithm: BipartitePropertyAlgorithm {}
