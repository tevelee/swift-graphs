import Foundation

struct CompositeTreePropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> where Graph.VertexDescriptor: Hashable {
    typealias Visitor = CompositeTreeProperty<Graph>.Visitor
    
    let connectedAlgorithm: any ConnectedPropertyAlgorithm<Graph>
    let cyclicAlgorithm: any CyclicPropertyAlgorithm<Graph>
    
    init(
        connectedAlgorithm: any ConnectedPropertyAlgorithm<Graph>,
        cyclicAlgorithm: any CyclicPropertyAlgorithm<Graph>
    ) {
        self.connectedAlgorithm = connectedAlgorithm
        self.cyclicAlgorithm = cyclicAlgorithm
    }
    
    func isTree(
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
    
    private func checkConnectivity(_ graph: Graph) -> Bool {
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
    
    private func checkAcyclicity(_ graph: Graph) -> Bool {
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

struct CompositeTreeProperty<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> where Graph.VertexDescriptor: Hashable {
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor
    
    struct Visitor {
        var checkEdgeCount: ((Int, Int) -> Void)?
        var edgeCountMismatch: ((Int, Int) -> Void)?
        var checkConnectivity: (() -> Void)?
        var connectivityResult: ((Bool) -> Void)?
        var checkAcyclicity: (() -> Void)?
        var acyclicityResult: ((Bool) -> Void)?
    }
}

// Note: VisitorSupporting conformance requires Composable implementation
// For now, we'll skip this to focus on core functionality
