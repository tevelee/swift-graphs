/// Johnson's algorithm for computing shortest paths between all pairs of vertices.
///
/// Johnson's algorithm is a method for finding shortest paths between all pairs of vertices
/// in a sparse graph. It works by reweighting the graph to eliminate negative edges,
/// then running Dijkstra's algorithm from each vertex.
///
/// - Complexity: O(V² log V + VE) where V is the number of vertices and E is the number of edges
public struct Johnson<
    Graph: IncidenceGraph & VertexListGraph & EdgePropertyGraph,
    Weight: AdditiveArithmetic & Comparable
> where
    Graph.VertexDescriptor: Hashable,
    Weight: Numeric,
    Weight.Magnitude == Weight
{
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    /// The edge type of the graph.
    public typealias Edge = Graph.EdgeDescriptor
    
    /// A visitor that can be used to observe Johnson's algorithm progress.
    public struct Visitor {
        /// Called when examining a vertex.
        public var examineVertex: ((Vertex) -> Void)?
        /// Called when examining an edge.
        public var examineEdge: ((Edge) -> Void)?
        /// Called when reweighting an edge.
        public var reweightEdge: ((Edge, Weight) -> Void)?
        /// Called when starting Dijkstra from a source vertex.
        public var startDijkstraFromSource: ((Vertex) -> Void)?
        /// Called when completing Dijkstra from a source vertex.
        public var completeDijkstraFromSource: ((Vertex) -> Void)?
        /// Called when a negative cycle is detected.
        public var detectNegativeCycle: (() -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            examineVertex: ((Vertex) -> Void)? = nil,
            examineEdge: ((Edge) -> Void)? = nil,
            reweightEdge: ((Edge, Weight) -> Void)? = nil,
            startDijkstraFromSource: ((Vertex) -> Void)? = nil,
            completeDijkstraFromSource: ((Vertex) -> Void)? = nil,
            detectNegativeCycle: (() -> Void)? = nil
        ) {
            self.examineVertex = examineVertex
            self.examineEdge = examineEdge
            self.reweightEdge = reweightEdge
            self.startDijkstraFromSource = startDijkstraFromSource
            self.completeDijkstraFromSource = completeDijkstraFromSource
            self.detectNegativeCycle = detectNegativeCycle
        }
    }
    
    @usableFromInline
    let edgeWeight: CostDefinition<Graph, Weight>
    
    /// Creates a new Johnson algorithm instance.
    ///
    /// - Parameter edgeWeight: The cost definition for edge weights.
    @inlinable
    public init(
        edgeWeight: CostDefinition<Graph, Weight>
    ) {
        self.edgeWeight = edgeWeight
    }
    
    /// Computes shortest paths between all pairs of vertices.
    ///
    /// - Parameters:
    ///   - graph: The graph to compute shortest paths for.
    ///   - visitor: An optional visitor to observe the algorithm's progress.
    /// - Returns: The shortest paths between all pairs of vertices.
    @inlinable
    public func shortestPathsForAllPairs(in graph: Graph, visitor: Visitor? = nil) -> AllPairsShortestPaths<Vertex, Edge, Weight> {
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
            
            // Process all vertices and get the final result
            var lastResult: Dijkstra<Graph, Weight>.Result? = nil
            for result in dijkstra {
                lastResult = result
            }
            
            guard let result = lastResult else {
                visitor?.completeDijkstraFromSource?(source)
                continue
            }
            
            // Extract distances and predecessors from property map
            for destination in vertices {
                let cost = result.propertyMap[destination][result.distanceProperty]
                switch cost {
                case .infinite:
                    continue // Keep as infinite
                case .finite(let distance):
                    let sourceReweighting = reweightingValues[source] ?? .zero
                    let destinationReweighting = reweightingValues[destination] ?? .zero
                    let adjustedDistance = distance - sourceReweighting + destinationReweighting
                    allDistances[source]?[destination] = .finite(adjustedDistance)
                }
                
                let predecessor = result.propertyMap[destination][result.predecessorEdgeProperty]
                allPredecessors[source]?[destination] = predecessor
            }
            
            visitor?.completeDijkstraFromSource?(source)
        }
        
        return AllPairsShortestPaths(
            distances: allDistances,
            predecessors: allPredecessors
        )
    }
    
    /// Computes reweighting values for the graph.
    ///
    /// - Parameter graph: The graph to compute reweighting values for.
    /// - Returns: A dictionary mapping vertices to their reweighting values.
    @usableFromInline
    func computeReweightingValues(in graph: Graph) -> [Vertex: Weight] {
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
    
    /// Creates a reweighted cost definition.
    ///
    /// - Parameter reweightingValues: The reweighting values for vertices.
    /// - Returns: A cost definition that applies reweighting.
    @usableFromInline
    func createReweightedCostDefinition(reweightingValues: [Vertex: Weight]) -> CostDefinition<Graph, Weight> {
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
    @inlinable
    public func shortestPathsForAllPairs(in graph: Graph) -> AllPairsShortestPaths<Vertex, Edge, Weight> {
        shortestPathsForAllPairs(in: graph, visitor: nil)
    }
}

extension Johnson: VisitorSupporting {}

