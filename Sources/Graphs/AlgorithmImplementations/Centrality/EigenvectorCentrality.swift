import Collections

/// Eigenvector centrality algorithm implementation.
///
/// Eigenvector centrality measures a vertex's importance based on the importance
/// of its neighbors. A vertex is important if it's connected to other important vertices.
/// This creates a recursive definition of importance.
///
/// The algorithm uses power iteration to converge to the principal eigenvector of
/// the adjacency matrix. Vertices with no incoming edges (isolated vertices) have
/// an eigenvector centrality of 0.
///
/// - Complexity: O(k × (V + E)) where k is the number of iterations until convergence
public struct EigenvectorCentralityAlgorithm<Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph>: CentralityAlgorithm where Graph.VertexDescriptor: Hashable {
    public typealias Visitor = EigenvectorCentrality<Graph>.Visitor
    
    /// The maximum number of iterations.
    ///
    /// The algorithm will stop after this many iterations even if convergence hasn't been reached.
    public let maxIterations: Int
    
    /// The convergence threshold.
    ///
    /// The algorithm stops when the maximum change in centrality between iterations is less than this value.
    public let tolerance: Double
    
    /// Creates a new eigenvector centrality algorithm.
    ///
    /// - Parameters:
    ///   - maxIterations: Maximum number of iterations (default: 100)
    ///   - tolerance: Convergence threshold (default: 1e-6)
    @inlinable
    public init(maxIterations: Int = 100, tolerance: Double = 1e-6) {
        self.maxIterations = maxIterations
        self.tolerance = tolerance
    }
    
    @inlinable
    public func centrality(in graph: Graph, visitor: Visitor?) -> CentralityResult<Graph.VertexDescriptor> {
        let eigenvector = EigenvectorCentrality(on: graph, maxIterations: maxIterations, tolerance: tolerance)
        return eigenvector.compute(visitor: visitor)
    }
}

/// Eigenvector centrality computation implementation using power iteration.
public struct EigenvectorCentrality<Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph> where Graph.VertexDescriptor: Hashable {
    /// A visitor that can be used to observe eigenvector centrality computation progress.
    public struct Visitor {
        /// Called at the start of each iteration.
        public var startIteration: ((Int) -> Void)?
        /// Called at the end of each iteration with the current centrality values.
        public var endIteration: ((Int, [Graph.VertexDescriptor: Double]) -> Void)?
        /// Called when convergence is achieved.
        public var converge: ((Int, [Graph.VertexDescriptor: Double]) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            startIteration: ((Int) -> Void)? = nil,
            endIteration: ((Int, [Graph.VertexDescriptor: Double]) -> Void)? = nil,
            converge: ((Int, [Graph.VertexDescriptor: Double]) -> Void)? = nil
        ) {
            self.startIteration = startIteration
            self.endIteration = endIteration
            self.converge = converge
        }
    }
    
    @usableFromInline
    let graph: Graph
    @usableFromInline
    let maxIterations: Int
    @usableFromInline
    let tolerance: Double
    
    @inlinable
    public init(on graph: Graph, maxIterations: Int, tolerance: Double) {
        self.graph = graph
        self.maxIterations = maxIterations
        self.tolerance = tolerance
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
            // Eigenvector centrality is 1.0 for single vertex (normalized)
            return CentralityResult(values: [vertices[0]: 1.0])
        }
        
        // Initialize centrality values
        var centrality = Dictionary(uniqueKeysWithValues: vertices.map { ($0, 1.0) })
        var newCentrality: [Graph.VertexDescriptor: Double] = [:]
        
        for iteration in 0..<maxIterations {
            visitor?.startIteration?(iteration)
            
            // Initialize new centrality
            for vertex in vertices {
                newCentrality[vertex] = 0.0
            }
            
            // Compute new centrality based on incoming edges (neighbors' importance)
            for vertex in vertices {
                var sum = 0.0
                for edge in graph.incomingEdges(of: vertex) {
                    if let neighbor = graph.source(of: edge) {
                        sum += centrality[neighbor] ?? 0.0
                    }
                }
                newCentrality[vertex] = sum
            }
            
            // Normalize by maximum value to prevent overflow
            let maxValue = newCentrality.values.max() ?? 1.0
            if maxValue > 0 {
                for vertex in vertices {
                    newCentrality[vertex] = newCentrality[vertex, default: 0.0] / maxValue
                }
            }
            
            visitor?.endIteration?(iteration, newCentrality)
            
            // Check for convergence
            var maxDiff = 0.0
            for vertex in vertices {
                let newValue = newCentrality[vertex] ?? 0.0
                let oldValue = centrality[vertex] ?? 0.0
                let diff = abs(newValue - oldValue)
                maxDiff = max(maxDiff, diff)
            }
            
            if maxDiff < tolerance {
                visitor?.converge?(iteration, newCentrality)
                return CentralityResult(values: newCentrality)
            }
            
            centrality = newCentrality
            newCentrality = [:]
        }
        
        return CentralityResult(values: centrality)
    }
}

extension EigenvectorCentralityAlgorithm: VisitorSupporting {}

