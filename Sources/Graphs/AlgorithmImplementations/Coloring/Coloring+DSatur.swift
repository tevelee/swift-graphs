import Foundation

extension ColoringAlgorithm where Color == Int {
    static func dsatur<Graph: IncidenceGraph & VertexListGraph>(
        on graph: Graph
    ) -> Self where Self == DSaturColoringAlgorithm<Graph, Int>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}
