import Foundation

struct BellmanFord<
    Graph: IncidenceGraph & EdgeListGraph & EdgePropertyGraph & VertexListGraph,
    Weight: Numeric & Comparable
> where
    Graph.VertexDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor
    
    struct Visitor {
        var examineVertex: ((Vertex) -> Void)?
        var examineEdge: ((Edge) -> Void)?
        var edgeRelaxed: ((Edge) -> Void)?
        var edgeNotRelaxed: ((Edge) -> Void)?
        var detectNegativeCycle: ((Edge) -> Void)?
        var completeRelaxationIteration: ((Int) -> Void)?
    }
    
    struct Result {
        let distances: [Vertex: Cost<Weight>]
        let predecessors: [Vertex: Edge?]
        let hasNegativeCycle: Bool
    }
    
    private let graph: Graph
    private let edgeWeight: CostDefinition<Graph, Weight>
    
    init(
        on graph: Graph,
        edgeWeight: CostDefinition<Graph, Weight>
    ) {
        self.graph = graph
        self.edgeWeight = edgeWeight
    }
    
    func shortestPathsFromSource(_ source: Vertex, visitor: Visitor? = nil) -> Result {
        var distances: [Vertex: Cost<Weight>] = [:]
        var predecessors: [Vertex: Edge?] = [:]
        
        // Initialize distances
        for vertex in graph.vertices() {
            distances[vertex] = .infinite
            predecessors[vertex] = nil
        }
        distances[source] = .finite(.zero)
        
        // Relax edges |V| - 1 times
        let vertices = Array(graph.vertices())
        for iteration in 0..<vertices.count - 1 {
            var relaxed = false
            
            for edge in graph.edges() {
                guard let sourceVertex = graph.source(of: edge),
                      let destinationVertex = graph.destination(of: edge) else { continue }
                
                visitor?.examineEdge?(edge)
                
                let sourceCost = distances[sourceVertex]!
                let weight = edgeWeight.costToExplore(edge, graph)
                let newCost = sourceCost + weight
                
                let destinationCost = distances[destinationVertex]!
                if newCost < destinationCost {
                    distances[destinationVertex] = newCost
                    predecessors[destinationVertex] = edge
                    relaxed = true
                    visitor?.edgeRelaxed?(edge)
                } else {
                    visitor?.edgeNotRelaxed?(edge)
                }
            }
            
            visitor?.completeRelaxationIteration?(iteration)
            if !relaxed { break }
        }
        
        // Check for negative cycles
        var hasNegativeCycle = false
        for edge in graph.edges() {
            guard let sourceVertex = graph.source(of: edge),
                  let destinationVertex = graph.destination(of: edge) else { continue }
            
            visitor?.examineEdge?(edge)
            
            let sourceCost = distances[sourceVertex]!
            let weight = edgeWeight.costToExplore(edge, graph)
            let newCost = sourceCost + weight
            
            let destinationCost = distances[destinationVertex]!
            if newCost < destinationCost {
                hasNegativeCycle = true
                visitor?.detectNegativeCycle?(edge)
                break
            }
        }
        
        
        return Result(
            distances: distances,
            predecessors: predecessors,
            hasNegativeCycle: hasNegativeCycle
        )
    }
    
    func shortestPath(from source: Vertex, to destination: Vertex, visitor: Visitor? = nil) -> Path<Vertex, Edge>? {
        let result = shortestPathsFromSource(source, visitor: visitor)
        
        guard !result.hasNegativeCycle else {
            return nil // Cannot find shortest path if there's a negative cycle
        }
        
        guard case .finite = result.distances[destination] else {
            return nil // No path exists
        }
        
        // Reconstruct path
        var current = destination
        var vertices: [Vertex] = [destination]
        var edges: [Edge] = []
        
        while let edge = result.predecessors[current] {
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
}

extension BellmanFord: ShortestPathAlgorithm {
    func shortestPath(
        from source: Vertex,
        to destination: Vertex,
        in graph: Graph
    ) -> Path<Vertex, Edge>? {
        shortestPath(from: source, to: destination)
    }
}

extension BellmanFord: ShortestPathsFromSourceAlgorithm {
    func shortestPathsFromSource(
        _ source: Vertex,
        in graph: Graph
    ) -> ShortestPathsFromSource<Vertex, Edge, Weight> {
        let result = shortestPathsFromSource(source)
        
        // Convert Cost to Weight, filtering out infinite costs
        var distances: [Vertex: Weight] = [:]
        for (vertex, cost) in result.distances {
            if case .finite(let weight) = cost {
                distances[vertex] = weight
            }
        }
        
        return ShortestPathsFromSource(
            source: source,
            distances: distances,
            predecessors: result.predecessors
        )
    }
}

// Visitor support
extension BellmanFord {
    func withVisitor(_ makeVisitor: @escaping () -> Visitor) -> BellmanFordWithVisitor<Graph, Weight> {
        .init(base: self, makeVisitor: makeVisitor)
    }
}

struct BellmanFordWithVisitor<Graph: IncidenceGraph & EdgeListGraph & EdgePropertyGraph & VertexListGraph, Weight: Numeric & Comparable>
where Graph.VertexDescriptor: Hashable, Weight.Magnitude == Weight {
    typealias Base = BellmanFord<Graph, Weight>
    let base: Base
    let makeVisitor: () -> Base.Visitor
}

extension BellmanFordWithVisitor {
    func shortestPathsFromSource(_ source: Graph.VertexDescriptor) -> Base.Result {
        base.shortestPathsFromSource(source, visitor: makeVisitor())
    }
    
    func shortestPath(from source: Graph.VertexDescriptor, to destination: Graph.VertexDescriptor) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        base.shortestPath(from: source, to: destination, visitor: makeVisitor())
    }
}


