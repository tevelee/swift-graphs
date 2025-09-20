import Foundation

struct DFSTreePropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> where Graph.VertexDescriptor: Hashable {
    typealias Visitor = DFSTreeProperty<Graph>.Visitor
    
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

struct DFSTreeProperty<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> where Graph.VertexDescriptor: Hashable {
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor
    
    struct Visitor {
        var checkEdgeCount: ((Int, Int) -> Void)?
        var edgeCountMismatch: ((Int, Int) -> Void)?
        var discoverVertex: ((Vertex) -> Void)?
        var examineEdge: ((Edge) -> Void)?
        var backEdge: ((Edge) -> Void)?
        var connectivityResult: ((Bool) -> Void)?
        var acyclicityResult: ((Bool) -> Void)?
    }
}

// Note: VisitorSupporting conformance requires Composable implementation
// For now, we'll skip this to focus on core functionality
