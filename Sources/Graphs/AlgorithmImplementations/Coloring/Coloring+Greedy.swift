import Foundation

extension ColoringAlgorithm where Color == Int {
    static func greedy<Graph: IncidenceGraph & VertexListGraph>() -> Self where Self == GreedyColoringAlgorithm<Graph, Int>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}

extension GreedyColoringAlgorithm: ColoringAlgorithm {
    func color(graph: Graph) -> GraphColoring<Graph.VertexDescriptor, Color> {
        color(graph: graph, visitor: nil)
    }
}
