import Foundation

extension KShortestPathsAlgorithm where Weight: Numeric, Weight.Magnitude == Weight {
    static func yen<Graph: IncidenceGraph & EdgePropertyGraph, Weight>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == YenKShortestPath<Graph, Weight>, Graph.VertexDescriptor: Hashable {
        .init(weight: weight)
    }
}

struct YenKShortestPath<
    Graph: IncidenceGraph & EdgePropertyGraph,
    Weight: Numeric & Comparable
>: KShortestPathsAlgorithm where
    Graph.VertexDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    let weight: CostDefinition<Graph, Weight>
    
    func kShortestPaths(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        k: Int,
        in graph: Graph
    ) -> [Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>] {
        let yen = Yen(on: graph, edgeWeight: weight)
        return yen.kShortestPaths(from: source, to: destination, k: k)
    }
}
