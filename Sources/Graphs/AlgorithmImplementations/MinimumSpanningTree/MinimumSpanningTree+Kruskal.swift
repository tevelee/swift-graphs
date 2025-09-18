import Foundation

extension MinimumSpanningTreeAlgorithm where Weight: AdditiveArithmetic {
    static func kruskal<Graph: EdgeListGraph & IncidenceGraph & EdgePropertyGraph & VertexListGraph, Weight>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == Kruskal<Graph, Weight>, Graph.VertexDescriptor: Hashable {
        .init(edgeWeight: weight)
    }
}

extension Kruskal: MinimumSpanningTreeAlgorithm {
    func minimumSpanningTree(in graph: Graph, visitor: Visitor?) -> MinimumSpanningTree<Vertex, Edge, Weight> {
        let result = minimumSpanningTree(on: graph, visitor: visitor)
        return MinimumSpanningTree(
            edges: result.edges,
            totalWeight: result.totalWeight,
            vertices: result.vertices
        )
    }
}
