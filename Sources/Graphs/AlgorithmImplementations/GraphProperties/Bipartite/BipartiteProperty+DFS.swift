import Foundation

extension BipartitePropertyAlgorithm {
    /// Creates a DFS-based bipartite property algorithm.
    ///
    /// - Returns: A new DFS-based bipartite property algorithm
    @inlinable
    public static func dfs<Graph: IncidenceGraph & VertexListGraph>() -> Self where Self == DFSBipartitePropertyAlgorithm<Graph>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}

extension DFSBipartitePropertyAlgorithm: BipartitePropertyAlgorithm {}
