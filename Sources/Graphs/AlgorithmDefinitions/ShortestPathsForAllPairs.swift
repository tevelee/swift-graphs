import Foundation

protocol ShortestPathsForAllPairsAlgorithm<Graph, Weight> {
    associatedtype Graph: IncidenceGraph & VertexListGraph where Graph.VertexDescriptor: Hashable
    associatedtype Weight: AdditiveArithmetic & Comparable
    associatedtype Visitor
    
    func shortestPathsForAllPairs(in graph: Graph, visitor: Visitor?) -> AllPairsShortestPaths<Graph.VertexDescriptor, Graph.EdgeDescriptor, Weight>
}

struct AllPairsShortestPaths<Vertex: Hashable, Edge, Weight: AdditiveArithmetic & Comparable> {
    let distances: [Vertex: [Vertex: Cost<Weight>]]
    let predecessors: [Vertex: [Vertex: Edge?]]
    
    func distance(from source: Vertex, to destination: Vertex) -> Cost<Weight>? {
        distances[source]?[destination]
    }
    
    func hasPath(from source: Vertex, to destination: Vertex) -> Bool {
        guard let cost = distances[source]?[destination] else { return false }
        switch cost {
            case .infinite: return false
            case .finite: return true
        }
    }
    
    func path(from source: Vertex, to destination: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> Path<Vertex, Edge>? {
        guard predecessors[source]?[destination] != nil else {
            return nil
        }
        
        // Reconstruct path by following predecessors
        var current = destination
        var vertices: [Vertex] = [destination]
        var edges: [Edge] = []
        
        while let edge = predecessors[source]?[current] {
            guard let edge = edge else { break }
            edges.insert(edge, at: 0)
            guard let predecessor = graph.source(of: edge) else { break }
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
    
}

extension IncidenceGraph where Self: VertexListGraph {
    func shortestPathsForAllPairs<Weight: AdditiveArithmetic & Comparable>(
        using algorithm: some ShortestPathsForAllPairsAlgorithm<Self, Weight>
    ) -> AllPairsShortestPaths<VertexDescriptor, EdgeDescriptor, Weight> {
        algorithm.shortestPathsForAllPairs(in: self, visitor: nil)
    }
}

extension VisitorWrapper: ShortestPathsForAllPairsAlgorithm where Base: ShortestPathsForAllPairsAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    typealias Graph = Base.Graph
    typealias Weight = Base.Weight
    
    func shortestPathsForAllPairs(in graph: Base.Graph, visitor: Base.Visitor?) -> AllPairsShortestPaths<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor, Base.Weight> {
        base.shortestPathsForAllPairs(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
