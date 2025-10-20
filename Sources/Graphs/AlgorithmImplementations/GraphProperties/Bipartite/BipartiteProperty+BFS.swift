import Foundation

extension BipartitePropertyAlgorithm {
    /// Creates a BFS-based bipartite property algorithm.
    ///
    /// - Returns: A new BFS-based bipartite property algorithm
    @inlinable
    public static func bfs<Graph: IncidenceGraph & VertexListGraph>() -> Self where Self == BFSBipartitePropertyAlgorithm<Graph>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}

extension BFSBipartitePropertyAlgorithm: BipartitePropertyAlgorithm {}
