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
    
    private let edgeWeight: CostDefinition<Graph, Weight>
    
    init(
        edgeWeight: CostDefinition<Graph, Weight>
    ) {
        self.edgeWeight = edgeWeight
    }
    
    func shortestPathsForAllPairs(in graph: Graph, visitor: Visitor? = nil) -> AllPairsShortestPaths<Vertex, Edge, Weight> {
        let reweightingValues = computeReweightingValues(in: graph)
        
        guard !reweightingValues.isEmpty else {
            visitor?.detectNegativeCycle?()
            return AllPairsShortestPaths(distances: [:], predecessors: [:])
        }
        
        let vertices = Array(graph.vertices())
        var allDistances: [Vertex: [Vertex: Cost<Weight>]] = [:]
        var allPredecessors: [Vertex: [Vertex: Edge?]] = [:]
        
        for source in vertices {
            allDistances[source] = [:]
            allPredecessors[source] = [:]
            for destination in vertices {
                allDistances[source]?[destination] = source == destination ? .finite(.zero) : .infinite
                allPredecessors[source]?[destination] = nil
            }
        }
        for source in vertices {
            visitor?.startDijkstraFromSource?(source)
            
            let dijkstra = Dijkstra(
                on: graph,
                from: source,
                edgeWeight: createReweightedCostDefinition(reweightingValues: reweightingValues)
            )
            
            let dijkstraResult = dijkstra.allShortestPaths()
            
            for (destination, distance) in dijkstraResult.distances {
                let sourceReweighting = reweightingValues[source] ?? .zero
                let destinationReweighting = reweightingValues[destination] ?? .zero
                let adjustedDistance = distance - sourceReweighting + destinationReweighting
                allDistances[source]?[destination] = .finite(adjustedDistance)
            }
            
            for (destination, predecessor) in dijkstraResult.predecessors {
                allPredecessors[source]?[destination] = predecessor
            }
            
            visitor?.completeDijkstraFromSource?(source)
        }
        
        return AllPairsShortestPaths(
            distances: allDistances,
            predecessors: allPredecessors
        )
    }
    
    private func computeReweightingValues(in graph: Graph) -> [Vertex: Weight] {
        let vertices = Array(graph.vertices())
        var distances: [Vertex: Cost<Weight>] = [:]
        
        for vertex in vertices {
            distances[vertex] = .infinite
        }
        
        for iteration in 0 ..< vertices.count {
            var wasRelaxed = false
            
            if iteration == 0 {
                for vertex in vertices {
                    if (distances[vertex] ?? .infinite) > .finite(.zero) {
                        distances[vertex] = .finite(.zero)
                        wasRelaxed = true
                    }
                }
            }
            
            for source in vertices {
                for edge in graph.outgoingEdges(of: source) {
                    guard let destination = graph.destination(of: edge) else { continue }
                    
                    let sourceCost = distances[source] ?? .infinite
                    let weight = edgeWeight.costToExplore(edge, graph)
                    let newCost = sourceCost + weight
                    
                    let destinationCost = distances[destination] ?? .infinite
                    if newCost < destinationCost {
                        distances[destination] = newCost
                        wasRelaxed = true
                    }
                }
            }
            
            if !wasRelaxed { break }
        }
        
        for source in vertices {
            for edge in graph.outgoingEdges(of: source) {
                guard let destination = graph.destination(of: edge) else { continue }
                
                let sourceCost = distances[source] ?? .infinite
                let weight = edgeWeight.costToExplore(edge, graph)
                let newCost = sourceCost + weight
                
                let destinationCost = distances[destination] ?? .infinite
                if newCost < destinationCost {
                    return [:]
                }
            }
        }
        
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
            let sourceReweighting = reweightingValues[source] ?? .zero
            let destinationReweighting = reweightingValues[destination] ?? .zero
            return originalWeight + sourceReweighting - destinationReweighting
        }
    }
}

extension Johnson: ShortestPathsForAllPairsAlgorithm {
    func shortestPathsForAllPairs(in graph: Graph) -> AllPairsShortestPaths<Vertex, Edge, Weight> {
        shortestPathsForAllPairs(in: graph, visitor: nil)
    }
}

extension Johnson {
    static func create<G: IncidenceGraph & VertexListGraph & EdgePropertyGraph, W: Numeric & Comparable>(
        edgeWeight: CostDefinition<G, W>
    ) -> Johnson<G, W> where G.VertexDescriptor: Hashable, W.Magnitude == W {
        Johnson<G, W>(edgeWeight: edgeWeight)
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
    func shortestPathsForAllPairs(in graph: Graph) -> AllPairsShortestPaths<Graph.VertexDescriptor, Graph.EdgeDescriptor, Weight> {
        base.shortestPathsForAllPairs(in: graph, visitor: makeVisitor())
    }
}

extension ShortestPathsForAllPairsAlgorithm {
    static func johnson<Graph: IncidenceGraph & VertexListGraph & EdgePropertyGraph, Weight: Numeric & Comparable>(
        edgeWeight: CostDefinition<Graph, Weight>
    ) -> Johnson<Graph, Weight> where Self == Johnson<Graph, Weight>, Graph.VertexDescriptor: Hashable, Weight.Magnitude == Weight {
        Johnson(edgeWeight: edgeWeight)
    }
}
