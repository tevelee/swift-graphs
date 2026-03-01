#if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
extension IsomorphismAlgorithm where Graph: IncidenceGraph & VertexListGraph & EdgeListGraph {
    /// Creates a Weisfeiler-Lehman isomorphism algorithm.
    ///
    /// - Parameter maxIterations: The maximum number of iterations to perform (default: 10)
    /// - Returns: A new Weisfeiler-Lehman isomorphism algorithm
    @inlinable
    public static func weisfeilerLehman<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph>(
        maxIterations: Int = 10
    ) -> Self where Self == WeisfeilerLehmanIsomorphism<Graph>, Graph.VertexDescriptor: Hashable {
        .init(maxIterations: maxIterations)
    }
}

extension WeisfeilerLehmanIsomorphism: IsomorphismAlgorithm {
    @inlinable
    public func areIsomorphic(_ graph1: Graph, _ graph2: Graph) -> Bool {
        areIsomorphic(graph1, graph2, visitor: nil)
    }
    
    @inlinable
    public func findIsomorphism(_ graph1: Graph, _ graph2: Graph) -> [Graph.VertexDescriptor: Graph.VertexDescriptor]? {
        findIsomorphism(graph1, graph2, visitor: nil)
    }
}

// MARK: - Enhanced Weisfeiler-Lehman Extension

extension IsomorphismAlgorithm where Graph: IncidenceGraph & VertexListGraph & EdgeListGraph {
    /// Creates an enhanced Weisfeiler-Lehman isomorphism algorithm.
    ///
    /// - Parameter maxIterations: The maximum number of iterations to perform (default: 10)
    /// - Returns: A new enhanced Weisfeiler-Lehman isomorphism algorithm
    @inlinable
    public static func enhancedWeisfeilerLehman<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph>(
        maxIterations: Int = 10
    ) -> Self where Self == EnhancedWeisfeilerLehmanIsomorphism<Graph>, Graph.VertexDescriptor: Hashable {
        .init(maxIterations: maxIterations)
    }
}

extension EnhancedWeisfeilerLehmanIsomorphism: IsomorphismAlgorithm {
    @inlinable
    public func areIsomorphic(_ graph1: Graph, _ graph2: Graph) -> Bool {
        areIsomorphic(graph1, graph2, visitor: nil)
    }
    
    @inlinable
    public func findIsomorphism(_ graph1: Graph, _ graph2: Graph) -> [Graph.VertexDescriptor: Graph.VertexDescriptor]? {
        findIsomorphism(graph1, graph2, visitor: nil)
    }
}
#endif
