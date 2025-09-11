import Foundation

extension ShortestPathsFromSourceAlgorithm where Weight: Numeric, Weight.Magnitude == Weight {
    static func bellmanFord<Graph: IncidenceGraph & EdgeListGraph & EdgePropertyGraph & VertexListGraph, Weight>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == BellmanFordFromSource<Graph, Weight>, Graph.VertexDescriptor: Hashable {
        .init(weight: weight)
    }
}

struct BellmanFordFromSource<
    Graph: IncidenceGraph & EdgeListGraph & EdgePropertyGraph & VertexListGraph,
    Weight: Numeric & Comparable
>: ShortestPathsFromSourceAlgorithm where
    Graph.VertexDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    let weight: CostDefinition<Graph, Weight>
    
    func shortestPathsFromSource(_ source: Graph.VertexDescriptor, in graph: Graph) -> ShortestPathsFromSource<Graph.VertexDescriptor, Graph.EdgeDescriptor, Weight> {
        let bellmanFord = BellmanFord(on: graph, edgeWeight: weight)
        let result = bellmanFord.shortestPathsFromSource(source)
        
        // Convert Cost<Weight> to Weight for distances
        let convertedDistances = result.distances.compactMapValues { cost in
            if case .finite(let weight) = cost {
                return weight
            }
            return nil
        }
        
        return ShortestPathsFromSource(
            source: source,
            distances: convertedDistances,
            predecessors: result.predecessors
        )
    }
}
