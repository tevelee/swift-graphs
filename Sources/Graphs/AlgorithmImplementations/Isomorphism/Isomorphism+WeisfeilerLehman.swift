import Foundation

extension IsomorphismAlgorithm where Graph: IncidenceGraph & VertexListGraph & EdgeListGraph {
    static func weisfeilerLehman<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph>(
        maxIterations: Int = 10
    ) -> Self where Self == WeisfeilerLehmanIsomorphism<Graph>, Graph.VertexDescriptor: Hashable {
        .init(maxIterations: maxIterations)
    }
}

extension WeisfeilerLehmanIsomorphism: IsomorphismAlgorithm {
    func areIsomorphic(_ graph1: Graph, _ graph2: Graph) -> Bool {
        areIsomorphic(graph1, graph2, visitor: nil)
    }
    
    func findIsomorphism(_ graph1: Graph, _ graph2: Graph) -> [Graph.VertexDescriptor: Graph.VertexDescriptor]? {
        findIsomorphism(graph1, graph2, visitor: nil)
    }
}

// MARK: - Enhanced Weisfeiler-Lehman Extension

extension IsomorphismAlgorithm where Graph: IncidenceGraph & VertexListGraph & EdgeListGraph {
    static func enhancedWeisfeilerLehman<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph>(
        maxIterations: Int = 10
    ) -> Self where Self == EnhancedWeisfeilerLehmanIsomorphism<Graph>, Graph.VertexDescriptor: Hashable {
        .init(maxIterations: maxIterations)
    }
}

extension EnhancedWeisfeilerLehmanIsomorphism: IsomorphismAlgorithm {
    func areIsomorphic(_ graph1: Graph, _ graph2: Graph) -> Bool {
        areIsomorphic(graph1, graph2, visitor: nil)
    }
    
    func findIsomorphism(_ graph1: Graph, _ graph2: Graph) -> [Graph.VertexDescriptor: Graph.VertexDescriptor]? {
        findIsomorphism(graph1, graph2, visitor: nil)
    }
}
