import Foundation

extension MinimumSpanningTreeAlgorithm where Weight: AdditiveArithmetic {
    static func boruvka<Graph: EdgeListGraph & IncidenceGraph & EdgePropertyGraph & VertexListGraph, Weight>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == Boruvka<Graph, Weight>, Graph.VertexDescriptor: Hashable {
        .init(edgeWeight: weight)
    }
}

extension Boruvka: MinimumSpanningTreeAlgorithm {
    func minimumSpanningTree(in graph: Graph, visitor: Visitor?) -> MinimumSpanningTree<Vertex, Edge, Weight> {
        let result = minimumSpanningTree(on: graph, visitor: visitor)
        return MinimumSpanningTree(
            edges: result.edges,
            totalWeight: result.totalWeight,
            vertices: result.vertices
        )
    }
}
