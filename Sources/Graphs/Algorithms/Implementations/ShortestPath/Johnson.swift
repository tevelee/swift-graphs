import Foundation

struct Johnson<
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
        var reweightEdge: ((Edge, Weight) -> Void)?
        var startDijkstraFromSource: ((Vertex) -> Void)?
        var completeDijkstraFromSource: ((Vertex) -> Void)?
        var detectNegativeCycle: (() -> Void)?
    }
    
    private let originalGraph: Graph
    private let edgeWeight: CostDefinition<Graph, Weight>
    
    init(
        on graph: Graph,
        edgeWeight: CostDefinition<Graph, Weight>
    ) {
        self.originalGraph = graph
        self.edgeWeight = edgeWeight
    }
    
    func shortestPathsForAllPairs(visitor: Visitor? = nil) -> AllPairsShortestPaths<Vertex, Edge, Weight> {
        // Step 1: Create a virtual augmented graph by simulating Bellman-Ford
        // We'll create a temporary graph structure for the Bellman-Ford step
        let reweightingValues = computeReweightingValues()
        
        
        // Check if we found negative cycles
        guard !reweightingValues.isEmpty else {
            // If there's a negative cycle, return empty result
            visitor?.detectNegativeCycle?()
            return AllPairsShortestPaths(distances: [:], predecessors: [:])
        }
        
        // Step 2: Initialize distance and predecessor matrices
        let vertices = Array(originalGraph.vertices())
        var allDistances: [Vertex: [Vertex: Cost<Weight>]] = [:]
        var allPredecessors: [Vertex: [Vertex: Edge?]] = [:]
        
        // Initialize with infinity for all pairs
        for source in vertices {
            allDistances[source] = [:]
            allPredecessors[source] = [:]
            for destination in vertices {
                allDistances[source]![destination] = source == destination ? .finite(.zero) : .infinite
                allPredecessors[source]![destination] = nil
            }
        }
        
        // Step 3: Run Dijkstra from each vertex on the reweighted graph
        for source in vertices {
            visitor?.startDijkstraFromSource?(source)
            
            let dijkstra = Dijkstra(
                on: originalGraph,
                from: source,
                edgeWeight: createReweightedCostDefinition(reweightingValues: reweightingValues)
            )
            
            let dijkstraResult = dijkstra.allShortestPaths()
            
            // Update distances and predecessors for reachable vertices
            for (destination, distance) in dijkstraResult.distances {
                // Adjust distance back to original weights: d(u,v) = d'(u,v) - h(u) + h(v)
                let adjustedDistance = distance - reweightingValues[source]! + reweightingValues[destination]!
                allDistances[source]![destination] = .finite(adjustedDistance)
            }
            
            for (destination, predecessor) in dijkstraResult.predecessors {
                allPredecessors[source]![destination] = predecessor
            }
            
            visitor?.completeDijkstraFromSource?(source)
        }
        
        
        return AllPairsShortestPaths(
            distances: allDistances,
            predecessors: allPredecessors
        )
    }
    
    private func computeReweightingValues() -> [Vertex: Weight] {
        // Simulate Bellman-Ford on an augmented graph by running it on the original graph
        // with a virtual source that has edges to all vertices with weight 0
        
        let vertices = Array(originalGraph.vertices())
        var distances: [Vertex: Cost<Weight>] = [:]
        
        // Initialize distances - all vertices start at infinity
        for vertex in vertices {
            distances[vertex] = .infinite
        }
        
        // Simulate the virtual source by initializing all vertices to 0
        // This is equivalent to having a virtual source connected to all vertices with weight 0
        // But we need to do this in the first iteration of Bellman-Ford
        
        // Run Bellman-Ford relaxation |V| times (including the virtual source)
        for iteration in 0..<vertices.count {
            var relaxed = false
            
            // In the first iteration, simulate edges from the virtual source (all vertices get distance 0)
            if iteration == 0 {
                for vertex in vertices {
                    if distances[vertex]! > .finite(.zero) {
                        distances[vertex] = .finite(.zero)
                        relaxed = true
                    }
                }
            }
            
            // Then relax all original edges
            for source in vertices {
                for edge in originalGraph.outgoingEdges(of: source) {
                    guard let destination = originalGraph.destination(of: edge) else { continue }
                    
                    let sourceCost = distances[source]!
                    let weight = edgeWeight.costToExplore(edge, originalGraph)
                    let newCost = sourceCost + weight
                    
                    let destinationCost = distances[destination]!
                    if newCost < destinationCost {
                        distances[destination] = newCost
                        relaxed = true
                    }
                }
            }
            
            if !relaxed { break }
        }
        
        // Check for negative cycles by doing one more relaxation
        for source in vertices {
            for edge in originalGraph.outgoingEdges(of: source) {
                guard let destination = originalGraph.destination(of: edge) else { continue }
                
                let sourceCost = distances[source]!
                let weight = edgeWeight.costToExplore(edge, originalGraph)
                let newCost = sourceCost + weight
                
                let destinationCost = distances[destination]!
                if newCost < destinationCost {
                    // Negative cycle detected
                    return [:]
                }
            }
        }
        
        // Extract reweighting values
        return Dictionary(uniqueKeysWithValues:
            vertices.compactMap { vertex in
                guard case .finite(let weight) = distances[vertex] else { return nil }
                return (vertex, weight)
            }
        )
    }
    
    private func createReweightedCostDefinition(reweightingValues: [Vertex: Weight]) -> CostDefinition<Graph, Weight> {
        return CostDefinition { edge, graph in
            guard let source = graph.source(of: edge),
                  let destination = graph.destination(of: edge) else {
                return .zero
            }
            
            let originalWeight = self.edgeWeight.costToExplore(edge, graph)
            let reweightedWeight = originalWeight + reweightingValues[source]! - reweightingValues[destination]!
            
            
            return reweightedWeight
        }
    }
}

extension Johnson: ShortestPathsForAllPairsAlgorithm {
    func shortestPathsForAllPairs(in graph: Graph) -> AllPairsShortestPaths<Vertex, Edge, Weight> {
        shortestPathsForAllPairs()
    }
}

extension Johnson {
    static func create<G: IncidenceGraph & VertexListGraph & EdgePropertyGraph, W: Numeric & Comparable>(
        on graph: G,
        edgeWeight: CostDefinition<G, W>
    ) -> Johnson<G, W> where G.VertexDescriptor: Hashable, W.Magnitude == W {
        Johnson<G, W>(on: graph, edgeWeight: edgeWeight)
    }
    
    func withVisitor(_ makeVisitor: @escaping () -> Visitor) -> JohnsonWithVisitor<Graph, Weight> {
        .init(base: self, makeVisitor: makeVisitor)
    }
}

struct JohnsonWithVisitor<Graph: IncidenceGraph & VertexListGraph & EdgePropertyGraph, Weight: Numeric & Comparable>
where Graph.VertexDescriptor: Hashable, Weight.Magnitude == Weight {
    typealias Base = Johnson<Graph, Weight>
    let base: Base
    let makeVisitor: () -> Base.Visitor
}

extension JohnsonWithVisitor {
    func shortestPathsForAllPairs() -> AllPairsShortestPaths<Graph.VertexDescriptor, Graph.EdgeDescriptor, Weight> {
        base.shortestPathsForAllPairs(visitor: makeVisitor())
    }
}

extension ShortestPathsForAllPairsAlgorithm {
    static func johnson<Graph: IncidenceGraph & VertexListGraph & EdgePropertyGraph, Weight: Numeric & Comparable>(
        on graph: Graph,
        edgeWeight: CostDefinition<Graph, Weight>
    ) -> Johnson<Graph, Weight> where Self == Johnson<Graph, Weight>, Graph.VertexDescriptor: Hashable, Weight.Magnitude == Weight {
        Johnson(on: graph, edgeWeight: edgeWeight)
    }
}
