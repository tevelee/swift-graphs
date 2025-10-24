/// The Bellman-Ford algorithm for finding shortest paths in graphs with negative edge weights.
///
/// Bellman-Ford can handle graphs with negative edge weights and detects negative cycles.
/// It has a time complexity of O(VE) where V is the number of vertices and E is the number of edges.
public struct BellmanFord<
    Graph: IncidenceGraph & EdgeListGraph & VertexListGraph,
    Weight: AdditiveArithmetic & Comparable
> where
    Graph.VertexDescriptor: Hashable
{
    public typealias Vertex = Graph.VertexDescriptor
    public typealias Edge = Graph.EdgeDescriptor
    
    /// A visitor for Bellman-Ford algorithm events.
    ///
    /// Visitors can observe the algorithm's progress including edge relaxations,
    /// negative cycle detection, and iteration completion.
    public struct Visitor {
        public var examineVertex: ((Vertex) -> Void)?
        public var examineEdge: ((Edge) -> Void)?
        public var edgeRelaxed: ((Edge) -> Void)?
        public var edgeNotRelaxed: ((Edge) -> Void)?
        public var detectNegativeCycle: ((Edge) -> Void)?
        public var completeRelaxationIteration: ((Int) -> Void)?
        
        @inlinable
        public init(
            examineVertex: ((Vertex) -> Void)? = nil,
            examineEdge: ((Edge) -> Void)? = nil,
            edgeRelaxed: ((Edge) -> Void)? = nil,
            edgeNotRelaxed: ((Edge) -> Void)? = nil,
            detectNegativeCycle: ((Edge) -> Void)? = nil,
            completeRelaxationIteration: ((Int) -> Void)? = nil
        ) {
            self.examineVertex = examineVertex
            self.examineEdge = examineEdge
            self.edgeRelaxed = edgeRelaxed
            self.edgeNotRelaxed = edgeNotRelaxed
            self.detectNegativeCycle = detectNegativeCycle
            self.completeRelaxationIteration = completeRelaxationIteration
        }
    }
    
    /// A result from the Bellman-Ford algorithm.
    ///
    /// Contains the computed distances, predecessor edges, and whether a negative cycle was detected.
    public struct Result {
        public let distances: [Vertex: Cost<Weight>]
        public let predecessors: [Vertex: Edge?]
        public let hasNegativeCycle: Bool
        
        @inlinable
        public init(distances: [Vertex: Cost<Weight>], predecessors: [Vertex: Edge?], hasNegativeCycle: Bool) {
            self.distances = distances
            self.predecessors = predecessors
            self.hasNegativeCycle = hasNegativeCycle
        }
    }
    
    @usableFromInline
    let graph: Graph
    @usableFromInline
    let edgeWeight: CostDefinition<Graph, Weight>
    
    @inlinable
    public init(
        on graph: Graph,
        edgeWeight: CostDefinition<Graph, Weight>
    ) {
        self.graph = graph
        self.edgeWeight = edgeWeight
    }
    
    @inlinable
    public func shortestPathsFromSource(_ source: Vertex, visitor: Visitor? = nil) -> Result {
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
    
    @inlinable
    public func shortestPath(from source: Vertex, to destination: Vertex, visitor: Visitor? = nil) -> Path<Vertex, Edge>? {
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
            pathVertices.insert(predecessor, at: 0)
            currentVertex = predecessor
            if predecessor == source { break }
        }
        
        // Only add source if it's not already the first vertex
        if pathVertices.first != source {
            pathVertices.insert(source, at: 0)
        }
        
        return Path(
            source: source,
            destination: destination,
            vertices: pathVertices,
            edges: pathEdges
        )
    }
}

extension BellmanFord: ShortestPathAlgorithm {
    @inlinable
    public func shortestPath(
        from source: Vertex,
        to destination: Vertex,
        in graph: Graph,
        visitor: Visitor?
    ) -> Path<Vertex, Edge>? {
        shortestPath(from: source, to: destination)
    }
}

extension BellmanFord: VisitorSupporting {}


