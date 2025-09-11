import Foundation

extension MinimumSpanningTreeAlgorithm where Weight: Numeric, Weight.Magnitude == Weight {
    static func kruskal<Graph: EdgeListGraph & IncidenceGraph & EdgePropertyGraph & VertexListGraph, Weight>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == KruskalMinimumSpanningTreeAlgorithm<Graph, Weight>, Graph.VertexDescriptor: Hashable {
        .init(weight: weight)
    }
}

struct KruskalMinimumSpanningTreeAlgorithm<
    Graph: EdgeListGraph & IncidenceGraph & EdgePropertyGraph & VertexListGraph,
    Weight: Numeric & Comparable
>: MinimumSpanningTreeAlgorithm where
    Graph.VertexDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    let weight: CostDefinition<Graph, Weight>
    
    func minimumSpanningTree(in graph: Graph) -> MinimumSpanningTree<Graph.VertexDescriptor, Graph.EdgeDescriptor, Weight> {
        let kruskal = Kruskal(on: graph, edgeWeight: weight)
        let result = kruskal.minimumSpanningTree()
        
        return MinimumSpanningTree(
            edges: result.edges,
            totalWeight: result.totalWeight,
            vertices: result.vertices
        )
    }
}
