import Foundation

extension ShortestPathsForAllPairsAlgorithm where Weight: AdditiveArithmetic {
    static func floydWarshall<Graph: IncidenceGraph & VertexListGraph & EdgePropertyGraph, Weight>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == FloydWarshallAllPairs<Graph, Weight>, Graph.VertexDescriptor: Hashable {
        .init(weight: weight)
    }
}

struct FloydWarshallAllPairs<
    Graph: IncidenceGraph & VertexListGraph & EdgePropertyGraph,
    Weight: AdditiveArithmetic & Comparable
>: ShortestPathsForAllPairsAlgorithm where
    Graph.VertexDescriptor: Hashable
{
    let weight: CostDefinition<Graph, Weight>
    
    func shortestPathsForAllPairs(in graph: Graph) -> AllPairsShortestPaths<Graph.VertexDescriptor, Graph.EdgeDescriptor, Weight> {
        let floydWarshall = FloydWarshall(on: graph, edgeWeight: weight)
        return floydWarshall.shortestPathsForAllPairs()
    }
}
