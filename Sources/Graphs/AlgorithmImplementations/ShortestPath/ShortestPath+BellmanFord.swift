import Foundation

extension ShortestPathAlgorithm where Weight: AdditiveArithmetic {
    static func bellmanFord<Graph: IncidenceGraph & EdgeListGraph & EdgePropertyGraph & VertexListGraph, Weight>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == BellmanFordShortestPath<Graph, Weight>, Graph.VertexDescriptor: Hashable {
        .init(weight: weight)
    }
}

struct BellmanFordShortestPath<
    Graph: IncidenceGraph & EdgeListGraph & EdgePropertyGraph & VertexListGraph,
    Weight: AdditiveArithmetic & Comparable
>: ShortestPathAlgorithm where
    Graph.VertexDescriptor: Hashable
{
    let weight: CostDefinition<Graph, Weight>
    
    func shortestPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        let bellmanFord = BellmanFord(on: graph, edgeWeight: weight)
        let result = bellmanFord.shortestPathsFromSource(source)
        
        // Check if there's a negative cycle
        guard !result.hasNegativeCycle else { return nil }
        
        // Check if destination is reachable
        guard let distance = result.distances[destination], 
              case .finite = distance else { return nil }
        
        // Reconstruct path
        return reconstructPath(from: source, to: destination, predecessors: result.predecessors, in: graph)
    }
    
    private func reconstructPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        predecessors: [Graph.VertexDescriptor: Graph.EdgeDescriptor?],
        in graph: Graph
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        var path: [Graph.VertexDescriptor] = [destination]
        var edges: [Graph.EdgeDescriptor] = []
        var current = destination
        
        while current != source {
            guard let edge = predecessors[current] else { return nil }
            guard let unwrappedEdge = edge else { return nil }
            edges.append(unwrappedEdge)
            
            // Find the source vertex of this edge
            guard let sourceVertex = graph.source(of: unwrappedEdge) else { return nil }
            path.append(sourceVertex)
            current = sourceVertex
        }
        
        path.reverse()
        edges.reverse()
        
        return Path(
            source: source,
            destination: destination,
            vertices: path,
            edges: edges
        )
    }
}
