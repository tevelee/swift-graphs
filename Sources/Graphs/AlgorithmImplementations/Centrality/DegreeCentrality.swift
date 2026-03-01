#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
/// Degree centrality algorithm implementation.
///
/// Degree centrality measures the number of connections a vertex has.
/// It's the simplest centrality measure, counting the out-degree of each vertex.
///
/// For undirected graphs represented as directed graphs (with edges in both directions),
/// degree centrality counts outgoing edges. For proper normalization, consider using
/// total degree (in-degree + out-degree) with a `BidirectionalGraph`.
///
/// - Complexity: O(V + E)
public struct DegreeCentralityAlgorithm<Graph: IncidenceGraph & VertexListGraph>: CentralityAlgorithm where Graph.VertexDescriptor: Hashable {
    public typealias Visitor = DegreeCentrality<Graph>.Visitor
    
    /// Whether to normalize by maximum possible degree.
    ///
    /// When normalized, values are divided by the maximum degree in the graph,
    /// making them comparable across graphs of different sizes.
    public let normalized: Bool
    
    /// Creates a new degree centrality algorithm.
    ///
    /// - Parameter normalized: Whether to normalize values (default: true)
    @inlinable
    public init(normalized: Bool = true) {
        self.normalized = normalized
    }
    
    @inlinable
    public func centrality(in graph: Graph, visitor: Visitor?) -> CentralityResult<Graph.VertexDescriptor> {
        let degree = DegreeCentrality(on: graph, normalized: normalized)
        return degree.compute(visitor: visitor)
    }
}

/// Degree centrality computation implementation.
public struct DegreeCentrality<Graph: IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
    /// A visitor that can be used to observe degree centrality computation progress.
    public struct Visitor {
        /// Called when examining a vertex.
        public var examineVertex: ((Graph.VertexDescriptor) -> Void)?
        /// Called when computing the degree of a vertex.
        public var computeDegree: ((Graph.VertexDescriptor, Int) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            examineVertex: ((Graph.VertexDescriptor) -> Void)? = nil,
            computeDegree: ((Graph.VertexDescriptor, Int) -> Void)? = nil
        ) {
            self.examineVertex = examineVertex
            self.computeDegree = computeDegree
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
        
        var degree: [Graph.VertexDescriptor: Double] = [:]
        var maxDegree = 0
        
        for vertex in vertices {
            visitor?.examineVertex?(vertex)
            let deg = graph.outDegree(of: vertex)
            degree[vertex] = Double(deg)
            maxDegree = max(maxDegree, deg)
            visitor?.computeDegree?(vertex, deg)
        }
        
        // Normalize if requested
        if normalized && maxDegree > 0 {
            let maxDegreeDouble = Double(maxDegree)
            for vertex in vertices {
                degree[vertex] = degree[vertex, default: 0.0] / maxDegreeDouble
            }
        }
        
        return CentralityResult(values: degree)
    }
}

extension DegreeCentralityAlgorithm: VisitorSupporting {}
#endif
