import Foundation

extension ConnectedPropertyAlgorithm {
    static func traversing<Graph, Traversal>(
        using algorithm: Traversal,
        startingVertex: Graph.VertexDescriptor? = nil
    ) -> Self where Self == TraversalBasedConnectedPropertyAlgorithm<Graph, Traversal> {
        .init(using: algorithm) { graph in
            startingVertex ?? graph.vertices().first(where: { _ in true })
        }
    }
    
    static func dfs<Graph>() -> Self where Self == TraversalBasedConnectedPropertyAlgorithm<Graph, DFSTraversal<Graph>> {
        .traversing(using: .dfs())
    }
    
    static func bfs<Graph>() -> Self where Self == TraversalBasedConnectedPropertyAlgorithm<Graph, BFSTraversal<Graph>> {
        .traversing(using: .bfs())
    }
}

extension TraversalBasedConnectedPropertyAlgorithm: ConnectedPropertyAlgorithm where Traversal.Visitor: Composable, Traversal.Visitor.Other == Traversal.Visitor {}
