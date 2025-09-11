import Foundation

extension ShortestPathsFromSourceAlgorithm where Weight: Numeric, Weight.Magnitude == Weight {
    static func aStar<Graph: IncidenceGraph & EdgePropertyGraph, Weight>(
        weight: CostDefinition<Graph, Weight>,
        heuristic: Heuristic<Graph, Weight>
    ) -> Self where Self == AStarFromSource<Graph, Weight>, Graph.VertexDescriptor: Hashable {
        .init(weight: weight, heuristic: heuristic)
    }
}

struct AStarFromSource<
    Graph: IncidenceGraph & EdgePropertyGraph,
    Weight: Numeric & Comparable
>: ShortestPathsFromSourceAlgorithm where
    Graph.VertexDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    let weight: CostDefinition<Graph, Weight>
    let heuristic: Heuristic<Graph, Weight>
    
    func shortestPathsFromSource(
        _ source: Graph.VertexDescriptor,
        in graph: Graph
    ) -> ShortestPathsFromSource<Graph.VertexDescriptor, Graph.EdgeDescriptor, Weight> {
        let aStar = AStar(on: graph, from: source, edgeWeight: weight, heuristic: heuristic, calculateTotalCost: +)
        
        // Collect all reachable vertices and their distances
        var distances: [Graph.VertexDescriptor: Weight] = [:]
        var predecessors: [Graph.VertexDescriptor: Graph.EdgeDescriptor?] = [:]
        
        for result in aStar {
            distances[result.currentVertex] = result.currentDistance()
            predecessors[result.currentVertex] = result.predecessorEdge()
        }
        
        return ShortestPathsFromSource(
            source: source,
            distances: distances,
            predecessors: predecessors
        )
    }
}
