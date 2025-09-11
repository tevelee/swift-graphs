@testable import Graphs
import Testing

struct SearchTests {
    
    @Test func basicSearchAPI() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        let e = graph.addVertex()
        let f = graph.addVertex()
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: b, to: d)
        graph.addEdge(from: c, to: e)
        graph.addEdge(from: d, to: f)
        graph.addEdge(from: e, to: f)
        
        // Use search API with BFS - returns a sequence
        let bfsSequence = graph.search(from: a, using: .bfs())
        
        // Find first vertex matching condition
        let found = bfsSequence.first { result in
            result.currentVertex == f
        }
        
        #expect(found != nil)
        #expect(found?.currentVertex == f)
        #expect(found?.depth() == 3) // a -> b -> d -> f
        
        // Use search API with DFS
        let dfsSequence = graph.search(from: a, using: .dfs())
        
        // Collect vertices in DFS order
        let dfsOrder = dfsSequence.map { $0.currentVertex }
        let collected = Array(dfsOrder)
        
        #expect(collected.contains(a))
        #expect(collected.contains(f))
    }
    
    @Test func lazyEvaluation() {
        var graph = AdjacencyList()
        
        // Create a chain of vertices with meaningful names
        let start = graph.addVertex()
        let middle = graph.addVertex()
        let end = graph.addVertex()
        
        // Create additional vertices for the chain
        var chainVertices: [OrderedVertexStorage.Vertex] = [start]
        for _ in 1..<50 {
            chainVertices.append(graph.addVertex())
        }
        chainVertices.append(middle)
        for _ in 51..<100 {
            chainVertices.append(graph.addVertex())
        }
        chainVertices.append(end)
        
        // Add edges to create a chain: start -> ... -> middle -> ... -> end
        for i in 0..<chainVertices.count - 1 {
            graph.addEdge(from: chainVertices[i], to: chainVertices[i+1])
        }
        
        var visitCount = 0
        
        // Search with early termination - stop at middle vertex
        let result = graph.search(from: start, using: .bfs())
            .first { result in
                visitCount += 1
                return result.currentVertex == middle
            }
        
        #expect(result != nil)
        #expect(visitCount == 51) // Should only visit start through middle (51 vertices)
    }
    
    @Test func sequenceOperations() {
        var graph = AdjacencyList()
        let root = graph.addVertex()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        let e = graph.addVertex()
        let f = graph.addVertex()
        
        graph.addEdge(from: root, to: a)
        graph.addEdge(from: root, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: a, to: d)
        graph.addEdge(from: b, to: e)
        graph.addEdge(from: b, to: f)
        
        // Get vertices at depth 2
        let depthTwo = graph.search(from: root, using: .bfs())
            .filter { $0.depth() == 2 }
            .map { $0.currentVertex }
        
        let collected = Set(depthTwo)
        #expect(collected == Set([c, d, e, f]))
        
        // Limited depth search
        let limited = graph.search(from: root, using: .bfs())
            .prefix { $0.depth() <= 1 }
            .map { $0.currentVertex }
        
        let limitedCollected = Array(limited)
        #expect(limitedCollected.count == 3) // root, a, b
        
        // Check if any vertex exists at depth > 2
        let hasDeep = graph.search(from: root, using: .bfs())
            .contains { $0.depth() > 2 }
        
        #expect(hasDeep == false)
    }
    
    @Test func comparisonWithTraversal() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: b, to: d)
        graph.addEdge(from: c, to: d)
        
        // Traversal API - collects everything
        let traversalResult = graph.traverse(from: a, using: .bfs())
        let allVertices = traversalResult.vertices
        
        // Search API - lazy sequence
        let searchVertices = graph.search(from: a, using: .bfs())
            .map { $0.currentVertex }
        
        // They should produce the same vertices (though search is lazy)
        #expect(Array(searchVertices) == allVertices)
        
        // But search can terminate early
        let firstD = graph.search(from: a, using: .bfs())
            .first { $0.currentVertex == d }
        
        #expect(firstD != nil)
        #expect(firstD?.depth() == 2)
    }
}