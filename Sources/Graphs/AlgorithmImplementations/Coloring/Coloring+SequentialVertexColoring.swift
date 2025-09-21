import Foundation

extension ColoringAlgorithm where Color == Int {
    static func sequential<Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph>(
        orderUsing orderingAlgorithm: any VertexOrderingAlgorithm<Graph>
    ) -> Self where Self == SequentialVertexColoringAlgorithm<Graph, Int>, Graph.VertexDescriptor: Hashable {
        .init(using: orderingAlgorithm)
    }
}

extension SequentialVertexColoringAlgorithm: ColoringAlgorithm {
    func color(graph: Graph) -> GraphColoring<Graph.VertexDescriptor, Color> {
        color(graph: graph, visitor: nil)
    }
}
