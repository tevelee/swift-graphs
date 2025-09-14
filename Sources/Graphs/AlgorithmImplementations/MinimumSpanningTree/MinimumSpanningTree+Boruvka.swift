import Foundation

extension MinimumSpanningTreeAlgorithm where Weight: AdditiveArithmetic {
    static func boruvka<Graph: EdgeListGraph & IncidenceGraph & EdgePropertyGraph & VertexListGraph, Weight>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == BoruvkaMinimumSpanningTreeAlgorithm<Graph, Weight>, Graph.VertexDescriptor: Hashable {
        .init(weight: weight)
    }
}

struct BoruvkaMinimumSpanningTreeAlgorithm<
    Graph: EdgeListGraph & IncidenceGraph & EdgePropertyGraph & VertexListGraph,
    Weight: AdditiveArithmetic & Comparable
>: MinimumSpanningTreeAlgorithm where
    Graph.VertexDescriptor: Hashable
{
    let weight: CostDefinition<Graph, Weight>
    
    func minimumSpanningTree(in graph: Graph) -> MinimumSpanningTree<Graph.VertexDescriptor, Graph.EdgeDescriptor, Weight> {
        let boruvka = Boruvka(on: graph, edgeWeight: weight)
        let result = boruvka.minimumSpanningTree()
        
        return MinimumSpanningTree(
            edges: result.edges,
            totalWeight: result.totalWeight,
            vertices: result.vertices
        )
    }
}
