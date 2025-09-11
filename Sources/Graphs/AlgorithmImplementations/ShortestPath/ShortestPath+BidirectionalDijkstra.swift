import Foundation

extension ShortestPathAlgorithm where Weight: Numeric, Weight.Magnitude == Weight {
    static func bidirectionalDijkstra<Graph: IncidenceGraph & BidirectionalGraph & EdgePropertyGraph, Weight>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == BidirectionalDijkstraShortestPath<Graph, Weight>, Graph.VertexDescriptor: Hashable {
        .init(weight: weight)
    }
}

struct BidirectionalDijkstraShortestPath<
    Graph: IncidenceGraph & BidirectionalGraph & EdgePropertyGraph,
    Weight: Numeric & Comparable
>: ShortestPathAlgorithm where
    Graph.VertexDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    let weight: CostDefinition<Graph, Weight>
    
    func shortestPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        let bidirectionalDijkstra = BidirectionalDijkstra(on: graph, edgeWeight: weight)
        let result = bidirectionalDijkstra.shortestPath(from: source, to: destination)
        return result.path
    }
}
