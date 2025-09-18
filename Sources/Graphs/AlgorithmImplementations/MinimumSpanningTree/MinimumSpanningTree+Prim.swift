import Foundation

extension MinimumSpanningTreeAlgorithm where Weight: AdditiveArithmetic {
    static func prim<Graph: IncidenceGraph & EdgePropertyGraph & VertexListGraph, Weight>(
        weight: CostDefinition<Graph, Weight>,
        startVertex: Graph.VertexDescriptor? = nil
    ) -> Self where Self == Prim<Graph, Weight>, Graph.VertexDescriptor: Hashable {
        .init(edgeWeight: weight, startVertex: startVertex)
    }
}

extension Prim: MinimumSpanningTreeAlgorithm {
    func minimumSpanningTree(in graph: Graph, visitor: Visitor?) -> MinimumSpanningTree<Vertex, Edge, Weight> {
        let result = minimumSpanningTree(on: graph, visitor: visitor)
        return MinimumSpanningTree(
            edges: result.edges,
            totalWeight: result.totalWeight,
            vertices: result.vertices
        )
    }
}
