import Foundation

extension ColoringAlgorithm where Color == Int {
    static func dsatur<Graph: IncidenceGraph & VertexListGraph>() -> Self where Self == DSaturColoringAlgorithm<Graph, Int>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}

extension DSaturColoringAlgorithm: ColoringAlgorithm {
    func color(graph: Graph) -> GraphColoring<Graph.VertexDescriptor, Color> {
        color(graph: graph, visitor: nil)
    }
}
