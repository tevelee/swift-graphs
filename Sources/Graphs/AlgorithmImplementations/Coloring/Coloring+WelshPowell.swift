import Foundation

extension ColoringAlgorithm where Color == Int {
    static func welshPowell<Graph: IncidenceGraph & VertexListGraph>() -> Self where Self == WelshPowellColoringAlgorithm<Graph, Int>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}

extension WelshPowellColoringAlgorithm: ColoringAlgorithm {
    func color(graph: Graph) -> GraphColoring<Graph.VertexDescriptor, Color> {
        color(graph: graph, visitor: nil)
    }
}
