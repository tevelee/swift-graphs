import Collections

/// Betweenness centrality algorithm implementation.
///
/// Betweenness centrality measures how often a vertex appears on shortest paths
/// between other vertices. Vertices with high betweenness act as bridges or bottlenecks
/// in the network, making them critical for information flow.
///
/// This implementation uses Brandes' algorithm, which efficiently computes betweenness
/// by accumulating dependencies during a single BFS pass from each source vertex.
///
/// - Complexity: O(V × E) for unweighted graphs, O(V × E + V² log V) for weighted graphs
public struct BetweennessCentralityAlgorithm<Graph: IncidenceGraph & VertexListGraph>: CentralityAlgorithm where Graph.VertexDescriptor: Hashable {
    public typealias Visitor = BetweennessCentrality<Graph>.Visitor
    
    /// Whether to normalize the centrality values.
    ///
    /// When normalized, values are divided by (V-1)(V-2) for undirected graphs,
    /// making them comparable across graphs of different sizes.
    public let normalized: Bool
    
    /// Creates a new betweenness centrality algorithm.
    ///
    /// - Parameter normalized: Whether to normalize values (default: true)
    @inlinable
    public init(normalized: Bool = true) {
        self.normalized = normalized
    }
    
    @inlinable
    public func centrality(in graph: Graph, visitor: Visitor?) -> CentralityResult<Graph.VertexDescriptor> {
        let betweenness = BetweennessCentrality(on: graph, normalized: normalized)
        return betweenness.compute(visitor: visitor)
    }
}

/// Betweenness centrality computation implementation using Brandes' algorithm.
public struct BetweennessCentrality<Graph: IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
    /// A visitor that can be used to observe betweenness centrality computation progress.
    public struct Visitor {
        /// Called when examining a source vertex.
        public var examineVertex: ((Graph.VertexDescriptor) -> Void)?
        /// Called when a shortest path is found.
        public var foundShortestPath: ((Graph.VertexDescriptor, Graph.VertexDescriptor, Int) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            examineVertex: ((Graph.VertexDescriptor) -> Void)? = nil,
            foundShortestPath: ((Graph.VertexDescriptor, Graph.VertexDescriptor, Int) -> Void)? = nil
        ) {
            self.examineVertex = examineVertex
            self.foundShortestPath = foundShortestPath
        }
    }
    
    @usableFromInline
    let graph: Graph
    @usableFromInline
    let normalized: Bool
    
    @inlinable
    public init(on graph: Graph, normalized: Bool) {
        self.graph = graph
        self.normalized = normalized
    }
    
    @inlinable
    public func compute(visitor: Visitor?) -> CentralityResult<Graph.VertexDescriptor> {
        let vertices = Array(graph.vertices())
        
        // Handle empty graph
        guard !vertices.isEmpty else {
            return CentralityResult(values: [:])
        }
        
        // Handle single vertex graph
        guard vertices.count > 1 else {
            return CentralityResult(values: [vertices[0]: 0.0])
        }
        
        // Handle two vertex graph
        guard vertices.count > 2 else {
            let result: [Graph.VertexDescriptor: Double] = [
                vertices[0]: 0.0,
                vertices[1]: 0.0
            ]
            return CentralityResult(values: result)
        }
        
        var betweenness: [Graph.VertexDescriptor: Double] = Dictionary(uniqueKeysWithValues: vertices.map { ($0, 0.0) })
        
        // Brandes' algorithm: for each source vertex, compute shortest paths
        for source in vertices {
            visitor?.examineVertex?(source)
            
            // Single-source shortest paths using BFS
            var distances: [Graph.VertexDescriptor: Int] = [:]
            var pathCounts: [Graph.VertexDescriptor: Int] = [:]
            var predecessors: [Graph.VertexDescriptor: [Graph.VertexDescriptor]] = [:]
            var queue: [Graph.VertexDescriptor] = [source]
            
            distances[source] = 0
            pathCounts[source] = 1
            
            while !queue.isEmpty {
                let v = queue.removeFirst()
                
                for edge in graph.outgoingEdges(of: v) {
                    guard let w = graph.destination(of: edge) else { continue }
                    
                    // Discover w for the first time
                    if distances[w] == nil {
                        distances[w] = distances[v]! + 1
                        queue.append(w)
                        visitor?.foundShortestPath?(source, w, distances[w]!)
                    }
                    
                    // Count shortest paths to w through v
                    if distances[w] == distances[v]! + 1 {
                        pathCounts[w, default: 0] += pathCounts[v]!
                        predecessors[w, default: []].append(v)
                    }
                }
            }
            
            // Accumulate dependencies (Brandes' algorithm)
            var dependencies: [Graph.VertexDescriptor: Double] = Dictionary(uniqueKeysWithValues: vertices.map { ($0, 0.0) })
            
            // Process vertices in reverse order of distance
            let sortedVertices = vertices.filter { distances[$0] != nil }
                .sorted { (distances[$0] ?? Int.max) > (distances[$1] ?? Int.max) }
            
            for v in sortedVertices {
                guard let preds = predecessors[v], !preds.isEmpty else { continue }
                guard let pathCount = pathCounts[v], pathCount > 0 else { continue }
                
                let delta = (1.0 + (dependencies[v] ?? 0.0)) / Double(pathCount)
                
                for pred in preds {
                    guard let predPathCount = pathCounts[pred], predPathCount > 0 else { continue }
                    dependencies[pred, default: 0.0] += Double(predPathCount) * delta
                }
                
                if v != source {
                    betweenness[v, default: 0.0] += dependencies[v] ?? 0.0
                }
            }
        }
        
        // Normalize if requested
        if normalized {
            let n = Double(vertices.count)
            // For directed graphs: divide by (n-1)(n-2)
            // For undirected graphs, it would be (n-1)(n-2)/2, but we use directed normalization
            let factor = 1.0 / ((n - 1) * (n - 2))
            for vertex in vertices {
                betweenness[vertex] = betweenness[vertex, default: 0.0] * factor
            }
        }
        
        return CentralityResult(values: betweenness)
    }
}

extension BetweennessCentralityAlgorithm: VisitorSupporting {}

