/// A connected property algorithm based on graph traversal.
public struct TraversalBasedConnectedPropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph, Traversal: TraversalAlgorithm> where Graph.VertexDescriptor: Hashable, Traversal.Graph == Graph {
    public typealias Visitor = Traversal.Visitor
    
    @usableFromInline
    let using: Traversal
    @usableFromInline
    let startingVertex: (Graph) -> Graph.VertexDescriptor?
    
    /// Creates a new traversal-based connected property algorithm.
    ///
    /// - Parameters:
    ///   - traversalAlgorithm: The traversal algorithm to use
    ///   - startingVertex: A function that selects the starting vertex for traversal
    @inlinable
    public init(
        using traversalAlgorithm: Traversal,
        startingVertex: @escaping (Graph) -> Graph.VertexDescriptor?
    ) {
        self.using = traversalAlgorithm
        self.startingVertex = startingVertex
    }
    
    /// Checks if the graph is connected using traversal.
    ///
    /// - Parameters:
    ///   - graph: The graph to check
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: `true` if the graph is connected, `false` otherwise
    @inlinable
    public func isConnected(
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool {
        // Handle empty graphs
        guard graph.vertexCount > 0 else {
            return true
        }
        
        // Handle single vertex graphs
        guard graph.vertexCount > 1 else {
            return true
        }
        
        // Start traversal from the first vertex
        guard let firstVertex = startingVertex(graph) ?? graph.vertices().first(where: { _ in true }) else {
            return true
        }
        
        // Perform the traversal using the provided algorithm
        let result = using.traverse(from: firstVertex, in: graph, visitor: visitor)
        
        // Count unique vertices visited
        let uniqueVertices = Set(result.vertices)
        let verticesVisited = uniqueVertices.count
        let totalVertices = graph.vertexCount
        
        // Graph is connected if we visited all vertices
        return verticesVisited == totalVertices
    }
}

extension TraversalBasedConnectedPropertyAlgorithm: VisitorSupporting where Traversal.Visitor: Composable, Traversal.Visitor.Other == Traversal.Visitor {}
