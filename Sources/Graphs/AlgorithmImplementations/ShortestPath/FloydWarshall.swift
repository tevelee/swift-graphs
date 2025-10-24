/// Floyd-Warshall algorithm for computing shortest paths between all pairs of vertices.
///
/// The Floyd-Warshall algorithm is a dynamic programming algorithm that finds shortest paths
/// between all pairs of vertices in a weighted graph. It can handle negative edge weights
/// but cannot detect negative cycles.
///
/// - Complexity: O(V³) where V is the number of vertices
public struct FloydWarshall<
    Graph: IncidenceGraph & VertexListGraph,
    Weight: AdditiveArithmetic & Comparable
> where
    Graph.VertexDescriptor: Hashable
{
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    /// The edge type of the graph.
    public typealias Edge = Graph.EdgeDescriptor

    /// A visitor that can be used to observe the Floyd-Warshall algorithm's progress.
    public struct Visitor {
        /// Called when examining a vertex.
        public var examineVertex: ((Vertex) -> Void)?
        /// Called when examining an edge.
        public var examineEdge: ((Edge) -> Void)?
        /// Called when updating a distance between two vertices.
        public var updateDistance: ((Vertex, Vertex, Cost<Weight>) -> Void)?
        /// Called when completing an intermediate vertex.
        public var completeIntermediateVertex: ((Int) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            examineVertex: ((Vertex) -> Void)? = nil,
            examineEdge: ((Edge) -> Void)? = nil,
            updateDistance: ((Vertex, Vertex, Cost<Weight>) -> Void)? = nil,
            completeIntermediateVertex: ((Int) -> Void)? = nil
        ) {
            self.examineVertex = examineVertex
            self.examineEdge = examineEdge
            self.updateDistance = updateDistance
            self.completeIntermediateVertex = completeIntermediateVertex
        }
    }
    
    @usableFromInline
    let graph: Graph
    @usableFromInline
    let edgeWeight: CostDefinition<Graph, Weight>
    
    /// Creates a new Floyd-Warshall algorithm instance.
    ///
    /// - Parameters:
    ///   - graph: The graph to compute shortest paths for.
    ///   - edgeWeight: The cost definition for edge weights.
    @inlinable
    public init(
        on graph: Graph,
        edgeWeight: CostDefinition<Graph, Weight>
    ) {
        self.graph = graph
        self.edgeWeight = edgeWeight
    }
    
    /// Computes shortest paths between all pairs of vertices.
    ///
    /// - Parameter visitor: An optional visitor to observe the algorithm's progress.
    /// - Returns: The shortest paths between all pairs of vertices.
    @inlinable
    public func shortestPathsForAllPairs(visitor: Visitor? = nil) -> AllPairsShortestPaths<Vertex, Edge, Weight> {
        let vertices = Array(graph.vertices())
        let vertexCount = vertices.count
        
        var distances: [Vertex: [Vertex: Cost<Weight>]] = [:]
        var predecessors: [Vertex: [Vertex: Edge?]] = [:]
        
        for source in vertices {
            distances[source] = [:]
            predecessors[source] = [:]
            for destination in vertices {
                distances[source]?[destination] = source == destination ? .finite(.zero) : .infinite
                predecessors[source]?[destination] = nil
            }
        }
        
        for source in vertices {
            visitor?.examineVertex?(source)
            for edge in graph.outgoingEdges(of: source) {
                guard let destination = graph.destination(of: edge) else { continue }
                visitor?.examineEdge?(edge)
                let weight = edgeWeight.costToExplore(edge, graph)
                distances[source]?[destination] = .finite(weight)
                predecessors[source]?[destination] = edge
                visitor?.updateDistance?(source, destination, .finite(weight))
            }
        }
        
        for intermediateIndex in 0 ..< vertexCount {
            let intermediateVertex = vertices[intermediateIndex]
            visitor?.examineVertex?(intermediateVertex)
            
            for sourceIndex in 0 ..< vertexCount {
                let sourceVertex = vertices[sourceIndex]
                for destinationIndex in 0 ..< vertexCount {
                    let destinationVertex = vertices[destinationIndex]
                    
                    let currentDistance = distances[sourceVertex]?[destinationVertex] ?? .infinite
                    let sourceToIntermediate = distances[sourceVertex]?[intermediateVertex] ?? .infinite
                    let intermediateToDestination = distances[intermediateVertex]?[destinationVertex] ?? .infinite
                    let newDistance = sourceToIntermediate + intermediateToDestination
                    
                    if newDistance < currentDistance {
                        distances[sourceVertex]?[destinationVertex] = newDistance
                        let intermediatePredecessor = predecessors[intermediateVertex]?[destinationVertex]
                        predecessors[sourceVertex]?[destinationVertex] = intermediatePredecessor
                        visitor?.updateDistance?(sourceVertex, destinationVertex, newDistance)
                    }
                }
            }
            
            visitor?.completeIntermediateVertex?(intermediateIndex)
        }
        
        return AllPairsShortestPaths(
            distances: distances,
            predecessors: predecessors
        )
    }
}

extension FloydWarshall: ShortestPathsForAllPairsAlgorithm {
    @inlinable
    public func shortestPathsForAllPairs(in graph: Graph, visitor: Visitor?) -> AllPairsShortestPaths<Vertex, Edge, Weight> {
        shortestPathsForAllPairs()
    }
}

extension FloydWarshall: VisitorSupporting {}

extension FloydWarshall {
    /// Creates a new Floyd-Warshall algorithm instance.
    ///
    /// - Parameters:
    ///   - graph: The graph to compute shortest paths for.
    ///   - edgeWeight: The cost definition for edge weights.
    /// - Returns: A new Floyd-Warshall algorithm instance.
    @inlinable
    public static func create<G: IncidenceGraph & VertexListGraph, W: AdditiveArithmetic & Comparable>(
        on graph: G,
        edgeWeight: CostDefinition<G, W>
    ) -> FloydWarshall<G, W> where G.VertexDescriptor: Hashable {
        FloydWarshall<G, W>(on: graph, edgeWeight: edgeWeight)
    }
}


