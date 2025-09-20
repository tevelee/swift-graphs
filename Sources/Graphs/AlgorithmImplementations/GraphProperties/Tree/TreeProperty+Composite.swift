import Foundation

extension TreePropertyAlgorithm {
    static func composite<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph>(
        connectedAlgorithm: some ConnectedPropertyAlgorithm<Graph>,
        cyclicAlgorithm: some CyclicPropertyAlgorithm<Graph>
    ) -> Self where Self == CompositeTreePropertyAlgorithm<Graph> {
        .init(
            connectedAlgorithm: connectedAlgorithm,
            cyclicAlgorithm: cyclicAlgorithm
        )
    }
    
    static func dfs<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph>() -> Self where Self == CompositeTreePropertyAlgorithm<Graph> {
        .composite(
            connectedAlgorithm: .dfs(),
            cyclicAlgorithm: .dfs()
        )
    }
    
    static func bfs<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph>() -> Self where Self == CompositeTreePropertyAlgorithm<Graph> {
        .composite(
            connectedAlgorithm: .bfs(),
            cyclicAlgorithm: .dfs()
        )
    }
}

extension CompositeTreePropertyAlgorithm: TreePropertyAlgorithm {}
