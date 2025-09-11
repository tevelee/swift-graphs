import Foundation

struct FloydWarshall<
    Graph: IncidenceGraph & VertexListGraph & EdgePropertyGraph,
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
        var updateDistance: ((Vertex, Vertex, Cost<Weight>) -> Void)?
        var completeIntermediateVertex: ((Int) -> Void)?
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
    
    func shortestPathsForAllPairs(visitor: Visitor? = nil) -> AllPairsShortestPaths<Vertex, Edge, Weight> {
        let vertices = Array(graph.vertices())
        let n = vertices.count
        
        // Initialize distance and predecessor matrices
        var distances: [Vertex: [Vertex: Cost<Weight>]] = [:]
        var predecessors: [Vertex: [Vertex: Edge?]] = [:]
        
        // Initialize with infinity for all pairs
        for source in vertices {
            distances[source] = [:]
            predecessors[source] = [:]
            for destination in vertices {
                distances[source]![destination] = source == destination ? .finite(.zero) : .infinite
                predecessors[source]![destination] = nil
            }
        }
        
        // Initialize with direct edge weights
        for source in vertices {
            visitor?.examineVertex?(source)
            for edge in graph.outgoingEdges(of: source) {
                guard let destination = graph.destination(of: edge) else { continue }
                visitor?.examineEdge?(edge)
                let weight = edgeWeight.costToExplore(edge, graph)
                distances[source]![destination] = .finite(weight)
                predecessors[source]![destination] = edge
                visitor?.updateDistance?(source, destination, .finite(weight))
            }
        }
        
        // Floyd-Warshall main algorithm
        for k in 0..<n {
            let intermediate = vertices[k]
            visitor?.examineVertex?(intermediate)
            
            for i in 0..<n {
                let source = vertices[i]
                for j in 0..<n {
                    let destination = vertices[j]
                    
                    let currentDistance = distances[source]![destination]!
                    let newDistance = distances[source]![intermediate]! + distances[intermediate]![destination]!
                    
                    // Check if new path is shorter
                    if newDistance < currentDistance {
                        distances[source]![destination] = newDistance
                        predecessors[source]![destination] = predecessors[intermediate]![destination]
                        visitor?.updateDistance?(source, destination, newDistance)
                    }
                }
            }
            
            visitor?.completeIntermediateVertex?(k)
        }
        
        
        return AllPairsShortestPaths(
            distances: distances,
            predecessors: predecessors
        )
    }
}

extension FloydWarshall: ShortestPathsForAllPairsAlgorithm {
    func shortestPathsForAllPairs(in graph: Graph) -> AllPairsShortestPaths<Vertex, Edge, Weight> {
        shortestPathsForAllPairs()
    }
}

extension FloydWarshall {
    static func create<G: IncidenceGraph & VertexListGraph & EdgePropertyGraph, W: Numeric & Comparable>(
        on graph: G,
        edgeWeight: CostDefinition<G, W>
    ) -> FloydWarshall<G, W> where G.VertexDescriptor: Hashable, W.Magnitude == W {
        FloydWarshall<G, W>(on: graph, edgeWeight: edgeWeight)
    }
    
    func withVisitor(_ makeVisitor: @escaping () -> Visitor) -> FloydWarshallWithVisitor<Graph, Weight> {
        .init(base: self, makeVisitor: makeVisitor)
    }
}

struct FloydWarshallWithVisitor<Graph: IncidenceGraph & VertexListGraph & EdgePropertyGraph, Weight: Numeric & Comparable>
where Graph.VertexDescriptor: Hashable, Weight.Magnitude == Weight {
    typealias Base = FloydWarshall<Graph, Weight>
    let base: Base
    let makeVisitor: () -> Base.Visitor
}

extension FloydWarshallWithVisitor {
    func shortestPathsForAllPairs() -> AllPairsShortestPaths<Graph.VertexDescriptor, Graph.EdgeDescriptor, Weight> {
        base.shortestPathsForAllPairs(visitor: makeVisitor())
    }
}


