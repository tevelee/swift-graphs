import Foundation

extension ColoringAlgorithm where Color == Int {
    static func welshPowell<Graph: IncidenceGraph & VertexListGraph>(
        on graph: Graph
    ) -> Self where Self == WelshPowellColoringAlgorithm<Graph, Int>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}
