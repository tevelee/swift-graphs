/// Composite algorithm for checking if a graph is a tree using separate connected and cyclic algorithms.
public struct CompositeTreePropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> where Graph.VertexDescriptor: Hashable {
    public typealias Visitor = CompositeTreeProperty<Graph>.Visitor
    
    @usableFromInline
    let connectedAlgorithm: any ConnectedPropertyAlgorithm<Graph>
    @usableFromInline
    let cyclicAlgorithm: any CyclicPropertyAlgorithm<Graph>
    
    /// Creates a new composite tree property algorithm.
    ///
    /// - Parameters:
    ///   - connectedAlgorithm: The connected property algorithm to use
    ///   - cyclicAlgorithm: The cyclic property algorithm to use
    @inlinable
    public init(
        connectedAlgorithm: any ConnectedPropertyAlgorithm<Graph>,
        cyclicAlgorithm: any CyclicPropertyAlgorithm<Graph>
    ) {
        self.connectedAlgorithm = connectedAlgorithm
        self.cyclicAlgorithm = cyclicAlgorithm
    }
    
    /// Checks if the graph is a tree using composite algorithms.
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
        
        // Check if graph is connected
        visitor?.checkConnectivity?()
        let isConnected = checkConnectivity(graph)
        visitor?.connectivityResult?(isConnected)
        
        if !isConnected {
            return false
        }
        
        // Check if graph is acyclic
        visitor?.checkAcyclicity?()
        let isCyclic = checkAcyclicity(graph)
        visitor?.acyclicityResult?(isCyclic)
        
        // A tree is connected and acyclic
        return !isCyclic
    }
    
    @usableFromInline
    func checkConnectivity(_ graph: Graph) -> Bool {
        // Use DFS to check connectivity
        var visitedVertices = Set<Graph.VertexDescriptor>()
        
        guard let firstVertex = graph.vertices().first(where: { _ in true }) else {
            return true
        }
        
        DepthFirstSearch(on: graph, from: firstVertex)
            .withVisitor { .init(discoverVertex: { visitedVertices.insert($0) }) }
            .forEach { _ in }
        
        return visitedVertices.count == graph.vertexCount
    }
    
    @usableFromInline
    func checkAcyclicity(_ graph: Graph) -> Bool {
        // Use DFS to check for cycles
        var hasCycle = false
        
        var visitedVertices = Set<Graph.VertexDescriptor>()
        
        for vertex in graph.vertices() {
            if !hasCycle && !visitedVertices.contains(vertex) {
                DepthFirstSearch(on: graph, from: vertex)
                    .withVisitor { .init(
                        discoverVertex: { visitedVertices.insert($0) },
                        backEdge: { _ in hasCycle = true }
                    ) }
                    .forEach { _ in }
            }
        }
        
        return hasCycle
    }
}

// MARK: - Visitor Support

public struct CompositeTreeProperty<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> where Graph.VertexDescriptor: Hashable {
    public typealias Vertex = Graph.VertexDescriptor
    public typealias Edge = Graph.EdgeDescriptor
    
    public struct Visitor {
        public var checkEdgeCount: ((Int, Int) -> Void)?
        public var edgeCountMismatch: ((Int, Int) -> Void)?
        public var checkConnectivity: (() -> Void)?
        public var connectivityResult: ((Bool) -> Void)?
        public var checkAcyclicity: (() -> Void)?
        public var acyclicityResult: ((Bool) -> Void)?
        
        public init(
            checkEdgeCount: ((Int, Int) -> Void)? = nil,
            edgeCountMismatch: ((Int, Int) -> Void)? = nil,
            checkConnectivity: (() -> Void)? = nil,
            connectivityResult: ((Bool) -> Void)? = nil,
            checkAcyclicity: (() -> Void)? = nil,
            acyclicityResult: ((Bool) -> Void)? = nil
        ) {
            self.checkEdgeCount = checkEdgeCount
            self.edgeCountMismatch = edgeCountMismatch
            self.checkConnectivity = checkConnectivity
            self.connectivityResult = connectivityResult
            self.checkAcyclicity = checkAcyclicity
            self.acyclicityResult = acyclicityResult
        }
    }
}

// Note: VisitorSupporting conformance requires Composable implementation
// For now, we'll skip this to focus on core functionality
