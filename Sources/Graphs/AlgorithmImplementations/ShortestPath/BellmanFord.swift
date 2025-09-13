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
        
        let vertices = Array(graph.vertices())
        for iteration in 0 ..< vertices.count - 1 {
            var wasRelaxed = false
            
            for edge in graph.edges() {
                guard let sourceVertex = graph.source(of: edge),
                      let destinationVertex = graph.destination(of: edge) else { 
                    continue 
                }
                
                visitor?.examineEdge?(edge)
                
                guard let sourceCost = distances[sourceVertex] else { continue }
                let weight = edgeWeight.costToExplore(edge, graph)
                let newCost = sourceCost + weight
                
                guard let destinationCost = distances[destinationVertex] else { continue }
                if newCost < destinationCost {
                    distances[destinationVertex] = newCost
                    predecessors[destinationVertex] = edge
                    wasRelaxed = true
                    visitor?.edgeRelaxed?(edge)
                } else {
                    visitor?.edgeNotRelaxed?(edge)
                }
            }
            
            visitor?.completeRelaxationIteration?(iteration)
            if !wasRelaxed { break }
        }
        
        var hasNegativeCycle = false
        for edge in graph.edges() {
            guard let sourceVertex = graph.source(of: edge),
                  let destinationVertex = graph.destination(of: edge) else { 
                continue 
            }
            
            visitor?.examineEdge?(edge)
            
            guard let sourceCost = distances[sourceVertex] else { continue }
            let weight = edgeWeight.costToExplore(edge, graph)
            let newCost = sourceCost + weight
            
            guard let destinationCost = distances[destinationVertex] else { continue }
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
            return nil
        }
        
        guard case .finite = result.distances[destination] else {
            return nil
        }
        
        var currentVertex = destination
        var pathVertices: [Vertex] = [destination]
        var pathEdges: [Edge] = []
        
        while let edge = result.predecessors[currentVertex] {
            guard let validEdge = edge else { break }
            pathEdges.insert(validEdge, at: 0)
            guard let predecessor = graph.source(of: validEdge) else { break }
            if predecessor == source { break }
            pathVertices.insert(predecessor, at: 0)
            currentVertex = predecessor
        }
        
        pathVertices.insert(source, at: 0)
        
        return Path(
            source: source,
            destination: destination,
            vertices: pathVertices,
            edges: pathEdges
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


extension BellmanFord: VisitorSupporting {}


