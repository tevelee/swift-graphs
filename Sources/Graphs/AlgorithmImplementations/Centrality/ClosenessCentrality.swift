#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
import Collections

/// Closeness centrality algorithm implementation.
///
/// Closeness centrality measures how close a vertex is to all other vertices in the graph.
/// It's computed as the inverse of the sum of shortest path distances to all other vertices.
/// Vertices with high closeness can reach all other vertices quickly.
///
/// For disconnected graphs, vertices that cannot reach all other vertices have
/// a closeness of 0.0.
///
/// - Complexity: O(V × (V + E)) for unweighted graphs
public struct ClosenessCentralityAlgorithm<Graph: IncidenceGraph & VertexListGraph>: CentralityAlgorithm where Graph.VertexDescriptor: Hashable {
    public typealias Visitor = ClosenessCentrality<Graph>.Visitor
    
    /// Creates a new closeness centrality algorithm.
    @inlinable
    public init() {}
    
    @inlinable
    public func centrality(in graph: Graph, visitor: Visitor?) -> CentralityResult<Graph.VertexDescriptor> {
        let closeness = ClosenessCentrality(on: graph)
        return closeness.compute(visitor: visitor)
    }
}

/// Closeness centrality computation implementation.
public struct ClosenessCentrality<Graph: IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
    /// A visitor that can be used to observe closeness centrality computation progress.
    public struct Visitor {
        /// Called when examining a vertex.
        public var examineVertex: ((Graph.VertexDescriptor) -> Void)?
        /// Called when computing distance from one vertex to another.
        public var computeDistance: ((Graph.VertexDescriptor, Graph.VertexDescriptor, Int) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            examineVertex: ((Graph.VertexDescriptor) -> Void)? = nil,
            computeDistance: ((Graph.VertexDescriptor, Graph.VertexDescriptor, Int) -> Void)? = nil
        ) {
            self.examineVertex = examineVertex
            self.computeDistance = computeDistance
        }
    }
    
    @usableFromInline
    let graph: Graph
    
    @inlinable
    public init(on graph: Graph) {
        self.graph = graph
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
            // Closeness is undefined for a single vertex, return 0
            return CentralityResult(values: [vertices[0]: 0.0])
        }
        
        var closeness: [Graph.VertexDescriptor: Double] = [:]
        let n = Double(vertices.count)
        
        for vertex in vertices {
            visitor?.examineVertex?(vertex)
            
            // BFS to compute distances from this vertex
            var distances: [Graph.VertexDescriptor: Int] = [:]
            var queue: [Graph.VertexDescriptor] = [vertex]
            distances[vertex] = 0
            
            while !queue.isEmpty {
                let v = queue.removeFirst()
                
                for edge in graph.outgoingEdges(of: v) {
                    guard let w = graph.destination(of: edge) else { continue }
                    
                    if distances[w] == nil {
                        guard let vDistance = distances[v] else { continue }
                        let wDistance = vDistance + 1
                        distances[w] = wDistance
                        queue.append(w)
                        visitor?.computeDistance?(vertex, w, wDistance)
                    }
                }
            }
            
            // Compute closeness: (n-1) / sum of distances
            // If vertex cannot reach all other vertices, closeness is 0
            let reachableCount = distances.count
            if reachableCount < vertices.count {
                // Disconnected: cannot reach all vertices
                closeness[vertex] = 0.0
            } else {
                let totalDistance = distances.values.reduce(0, +)
                if totalDistance > 0 {
                    closeness[vertex] = (n - 1.0) / Double(totalDistance)
                } else {
                    // All distances are 0 (shouldn't happen, but handle it)
                    closeness[vertex] = 0.0
                }
            }
        }
        
        return CentralityResult(values: closeness)
    }
}

extension ClosenessCentralityAlgorithm: VisitorSupporting {}
#endif
