import Foundation

extension ShortestPathAlgorithm where Weight: AdditiveArithmetic {
    static func floydWarshall<Graph: IncidenceGraph & VertexListGraph & EdgePropertyGraph, Weight>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == FloydWarshallShortestPath<Graph, Weight>, Graph.VertexDescriptor: Hashable {
        .init(weight: weight)
    }
}

struct FloydWarshallShortestPath<
    Graph: IncidenceGraph & VertexListGraph & EdgePropertyGraph,
    Weight: AdditiveArithmetic & Comparable
>: ShortestPathAlgorithm where
    Graph.VertexDescriptor: Hashable
{
    typealias Visitor = FloydWarshall<Graph, Weight>.Visitor
    
    let weight: CostDefinition<Graph, Weight>
    
    func shortestPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        let floydWarshall = FloydWarshall(on: graph, edgeWeight: weight)
        let allPairs = floydWarshall.shortestPathsForAllPairs(visitor: visitor)
        
        // Check if destination is reachable
        guard case .finite = allPairs.distance(from: source, to: destination) else { return nil }
        
        // Reconstruct path
        return reconstructPath(from: source, to: destination, predecessors: allPairs.predecessors, in: graph)
    }
    
    private func reconstructPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        predecessors: [Graph.VertexDescriptor: [Graph.VertexDescriptor: Graph.EdgeDescriptor?]],
        in graph: Graph
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        var path: [Graph.VertexDescriptor] = [destination]
        var edges: [Graph.EdgeDescriptor] = []
        var current = destination
        
        while current != source {
            guard let edge = predecessors[source]?[current] else { return nil }
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

extension FloydWarshallShortestPath: VisitorSupporting {}
