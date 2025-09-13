import Foundation

extension ColoringAlgorithm where Color == Int {
    static func greedy<Graph: IncidenceGraph & VertexListGraph>(
        on graph: Graph
    ) -> Self where Self == GreedyColoringAlgorithm<Graph, Int>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}
