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

    
    private let graph: Graph
    private let edgeWeight: CostDefinition<Graph, Weight>
    
    init(
        on graph: Graph,
        edgeWeight: CostDefinition<Graph, Weight>
    ) {
        self.graph = graph
        self.edgeWeight = edgeWeight
    }
    
    func shortestPathsForAllPairs() -> AllPairsShortestPaths<Vertex, Edge, Weight> {
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
            for edge in graph.outgoingEdges(of: source) {
                guard let destination = graph.destination(of: edge) else { continue }
                let weight = edgeWeight.costToExplore(edge, graph)
                distances[source]![destination] = .finite(weight)
                predecessors[source]![destination] = edge
            }
        }
        
        // Floyd-Warshall main algorithm
        for k in 0..<n {
            let intermediate = vertices[k]
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
                    }
                }
            }
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
}

extension ShortestPathsForAllPairsAlgorithm {
    static func floydWarshall<Graph: IncidenceGraph & VertexListGraph & EdgePropertyGraph, Weight: Numeric & Comparable>(
        on graph: Graph,
        edgeWeight: CostDefinition<Graph, Weight>
    ) -> FloydWarshall<Graph, Weight> where Self == FloydWarshall<Graph, Weight>, Graph.VertexDescriptor: Hashable, Weight.Magnitude == Weight {
        FloydWarshall(on: graph, edgeWeight: edgeWeight)
    }
}

