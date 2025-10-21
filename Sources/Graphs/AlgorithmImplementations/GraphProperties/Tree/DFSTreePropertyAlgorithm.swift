/// Single-pass DFS-based algorithm for checking if a graph is a tree.
public struct DFSTreePropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> where Graph.VertexDescriptor: Hashable {
    public typealias Visitor = DFSTreeProperty<Graph>.Visitor
    
    /// Creates a new single-pass DFS-based tree property algorithm.
    @inlinable
    public init() {}
    
    /// Checks if the graph is a tree using a single DFS pass.
    ///
    /// - Parameters:
    ///   - graph: The graph to check
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: `true` if the graph is a tree, `false` otherwise
    @inlinable
    public func isTree(
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool {
        // Handle empty graphs
        guard graph.vertexCount > 0 else {
            return true
        }
        
        // Handle single vertex graphs (they are trees)
        guard graph.vertexCount > 1 else {
            return true
        }
        
        // A tree must have exactly V-1 edges
        let expectedEdges = graph.vertexCount - 1
        let actualEdges = graph.edgeCount
        
        visitor?.checkEdgeCount?(expectedEdges, actualEdges)
        
        if actualEdges != expectedEdges {
            visitor?.edgeCountMismatch?(expectedEdges, actualEdges)
            return false
        }
        
        // Single DFS pass to check both connectivity and acyclicity
        var visitedVertices = Set<Graph.VertexDescriptor>()
        var hasCycle = false
        var verticesVisited = 0
        
        let treeVisitor = DepthFirstSearch<Graph>.Visitor(
            discoverVertex: { vertex in
                visitedVertices.insert(vertex)
                verticesVisited += 1
                visitor?.discoverVertex?(vertex)
            },
            examineEdge: { edge in
                visitor?.examineEdge?(edge)
            },
            backEdge: { edge in
                hasCycle = true
                visitor?.backEdge?(edge)
            }
        )
        
        // Start DFS from the first vertex
        guard let firstVertex = graph.vertices().first(where: { _ in true }) else {
            return true
        }
        
        DepthFirstSearch(on: graph, from: firstVertex)
            .withVisitor { treeVisitor }
            .forEach { _ in }
        
        visitor?.connectivityResult?(verticesVisited == graph.vertexCount)
        visitor?.acyclicityResult?(!hasCycle)
        
        // A tree is connected and acyclic
        return verticesVisited == graph.vertexCount && !hasCycle
    }
}

// MARK: - Visitor Support

public struct DFSTreeProperty<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> where Graph.VertexDescriptor: Hashable {
    public typealias Vertex = Graph.VertexDescriptor
    public typealias Edge = Graph.EdgeDescriptor
    
    public struct Visitor {
        public var checkEdgeCount: ((Int, Int) -> Void)?
        public var edgeCountMismatch: ((Int, Int) -> Void)?
        public var discoverVertex: ((Vertex) -> Void)?
        public var examineEdge: ((Edge) -> Void)?
        public var backEdge: ((Edge) -> Void)?
        public var connectivityResult: ((Bool) -> Void)?
        public var acyclicityResult: ((Bool) -> Void)?
        
        public init(
            checkEdgeCount: ((Int, Int) -> Void)? = nil,
            edgeCountMismatch: ((Int, Int) -> Void)? = nil,
            discoverVertex: ((Vertex) -> Void)? = nil,
            examineEdge: ((Edge) -> Void)? = nil,
            backEdge: ((Edge) -> Void)? = nil,
            connectivityResult: ((Bool) -> Void)? = nil,
            acyclicityResult: ((Bool) -> Void)? = nil
        ) {
            self.checkEdgeCount = checkEdgeCount
            self.edgeCountMismatch = edgeCountMismatch
            self.discoverVertex = discoverVertex
            self.examineEdge = examineEdge
            self.backEdge = backEdge
            self.connectivityResult = connectivityResult
            self.acyclicityResult = acyclicityResult
        }
    }
}

// Note: VisitorSupporting conformance requires Composable implementation
// For now, we'll skip this to focus on core functionality
