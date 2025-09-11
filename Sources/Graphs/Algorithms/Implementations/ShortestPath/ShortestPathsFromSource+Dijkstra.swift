import Foundation

extension ShortestPathsFromSourceAlgorithm where Weight: Numeric, Weight.Magnitude == Weight {
    static func dijkstra<Graph: IncidenceGraph & EdgePropertyGraph, Weight>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == DijkstraFromSource<Graph, Weight>, Graph.VertexDescriptor: Hashable {
        .init(weight: weight)
    }
}

struct DijkstraFromSource<
    Graph: IncidenceGraph & EdgePropertyGraph,
    Weight: Numeric & Comparable
>: ShortestPathsFromSourceAlgorithm where
    Graph.VertexDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    let weight: CostDefinition<Graph, Weight>
    
    func shortestPathsFromSource(
        _ source: Graph.VertexDescriptor,
        in graph: Graph
    ) -> ShortestPathsFromSource<Graph.VertexDescriptor, Graph.EdgeDescriptor, Weight> {
        let dijkstra = Dijkstra(on: graph, from: source, edgeWeight: weight)
        return dijkstra.allShortestPaths()
    }
}
