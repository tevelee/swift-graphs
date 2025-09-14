import Foundation

extension MinimumSpanningTreeAlgorithm where Weight: AdditiveArithmetic {
    static func prim<Graph: IncidenceGraph & EdgePropertyGraph, Weight>(
        weight: CostDefinition<Graph, Weight>,
        startVertex: Graph.VertexDescriptor? = nil
    ) -> Self where Self == PrimMinimumSpanningTreeAlgorithm<Graph, Weight>, Graph.VertexDescriptor: Hashable {
        .init(weight: weight, startVertex: startVertex)
    }
}

struct PrimMinimumSpanningTreeAlgorithm<
    Graph: IncidenceGraph & EdgePropertyGraph & VertexListGraph,
    Weight: AdditiveArithmetic & Comparable
>: MinimumSpanningTreeAlgorithm where
    Graph.VertexDescriptor: Hashable
{
    let weight: CostDefinition<Graph, Weight>
    let startVertex: Graph.VertexDescriptor?
    
    func minimumSpanningTree(in graph: Graph) -> MinimumSpanningTree<Graph.VertexDescriptor, Graph.EdgeDescriptor, Weight> {
        let prim = Prim(on: graph, edgeWeight: weight, startVertex: startVertex)
        let result = prim.minimumSpanningTree()
        
        return MinimumSpanningTree(
            edges: result.edges,
            totalWeight: result.totalWeight,
            vertices: result.vertices
        )
    }
}
