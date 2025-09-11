import Foundation

protocol ShortestPathsFromSourceAlgorithm<Graph, Weight> {
    associatedtype Graph: IncidenceGraph where Graph.VertexDescriptor: Hashable
    associatedtype Weight: Numeric & Comparable
    
    func shortestPathsFromSource(
        _ source: Graph.VertexDescriptor,
        in graph: Graph
    ) -> ShortestPathsFromSource<Graph.VertexDescriptor, Graph.EdgeDescriptor, Weight>
}

struct ShortestPathsFromSource<Vertex: Hashable, Edge, Weight: Numeric & Comparable> {
    let source: Vertex
    let distances: [Vertex: Weight]
    let predecessors: [Vertex: Edge?]
    
    func distance(to destination: Vertex) -> Weight? {
        distances[destination]
    }
    
    func path(to destination: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> Path<Vertex, Edge>? {
        guard let _ = distances[destination] else { return nil }
        
        // Reconstruct path by following predecessors
        var current = destination
        var vertices: [Vertex] = [destination]
        var edges: [Edge] = []
        
        while let edge = predecessors[current] {
            edges.insert(edge!, at: 0)
            guard let predecessor = graph.source(of: edge!) else { break }
            if predecessor == source { break }
            vertices.insert(predecessor, at: 0)
            current = predecessor
        }
        
        vertices.insert(source, at: 0)
        
        return Path(
            source: source,
            destination: destination,
            vertices: vertices,
            edges: edges
        )
    }
    
    func hasPath(to destination: Vertex) -> Bool {
        distances[destination] != nil
    }
}

extension IncidenceGraph {
    func shortestPathsFromSource<Weight: Numeric & Comparable>(
        _ source: VertexDescriptor,
        using algorithm: some ShortestPathsFromSourceAlgorithm<Self, Weight>
    ) -> ShortestPathsFromSource<VertexDescriptor, EdgeDescriptor, Weight> {
        algorithm.shortestPathsFromSource(source, in: self)
    }
}
