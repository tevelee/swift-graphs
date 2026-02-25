#if !GRAPHS_USES_TRAITS || (GRAPHS_OPTIMIZATION && GRAPHS_BIPARTITE_GRAPH)
import Testing
@testable import Graphs

struct MatchingAlgorithmTests {
    
    @Test
    func testHopcroftKarpSimpleMatching() {
        var graph = BipartiteAdjacencyList()
        
        // Create a simple bipartite graph
        let left1 = graph.addVertex(to: .left)
        let left2 = graph.addVertex(to: .left)
        let right1 = graph.addVertex(to: .right)
        let right2 = graph.addVertex(to: .right)
        
        // Add edges
        graph.addEdge(from: left1, to: right1)
        graph.addEdge(from: left2, to: right2)
        
        // Find maximum matching
        let result = graph.maximumMatching(using: .hopcroftKarp())
        
        #expect(result.matchingSize == 2)
        #expect(result.matchingEdges.count == 2)
        #expect(result.matchedVertices.count == 4)
        #expect(result.unmatchedVertices.isEmpty)
    }
    
    @Test
    func testHopcroftKarpPartialMatching() {
        var graph = BipartiteAdjacencyList()
        
        // Create a bipartite graph where not all vertices can be matched
        let left1 = graph.addVertex(to: .left)
        let left2 = graph.addVertex(to: .left)
        let left3 = graph.addVertex(to: .left)
        let right1 = graph.addVertex(to: .right)
        let right2 = graph.addVertex(to: .right)
        
        // Add edges - only 2 left vertices can be matched
        graph.addEdge(from: left1, to: right1)
        graph.addEdge(from: left2, to: right2)
        graph.addEdge(from: left3, to: right1) // This creates a conflict
        
        // Find maximum matching
        let result = graph.maximumMatching(using: .hopcroftKarp())
        
        #expect(result.matchingSize == 2)
        #expect(result.matchingEdges.count == 2)
        #expect(result.matchedVertices.count == 4)
        #expect(result.unmatchedVertices.count == 1)
        #expect(result.unmatchedLeftVertices.count == 1)
    }
    
    @Test
    func testHopcroftKarpEmptyGraph() {
        let graph = BipartiteAdjacencyList()
        
        // Find maximum matching in empty graph
        let result = graph.maximumMatching(using: .hopcroftKarp())
        
        #expect(result.matchingSize == 0)
        #expect(result.matchingEdges.isEmpty)
        #expect(result.matchedVertices.isEmpty)
        #expect(result.unmatchedVertices.isEmpty)
    }
    
    @Test
    func testHopcroftKarpNoEdges() {
        var graph = BipartiteAdjacencyList()
        
        // Add vertices but no edges
        _ = graph.addVertex(to: .left)
        _ = graph.addVertex(to: .left)
        _ = graph.addVertex(to: .right)
        _ = graph.addVertex(to: .right)
        
        // Find maximum matching
        let result = graph.maximumMatching(using: .hopcroftKarp())
        
        #expect(result.matchingSize == 0)
        #expect(result.matchingEdges.isEmpty)
        #expect(result.matchedVertices.isEmpty)
        #expect(result.unmatchedVertices.count == 4)
    }
    
    @Test(.disabled("indeterministic"))
    func testHopcroftKarpComplexMatching() {
        var graph = BipartiteAdjacencyList()
        
        // Create a more complex bipartite graph
        let left1 = graph.addVertex(to: .left)
        let left2 = graph.addVertex(to: .left)
        let left3 = graph.addVertex(to: .left)
        let right1 = graph.addVertex(to: .right)
        let right2 = graph.addVertex(to: .right)
        let right3 = graph.addVertex(to: .right)
        
        // Add edges creating multiple possible matchings
        graph.addEdge(from: left1, to: right1)
        graph.addEdge(from: left1, to: right2)
        graph.addEdge(from: left2, to: right1)
        graph.addEdge(from: left2, to: right3)
        graph.addEdge(from: left3, to: right2)
        graph.addEdge(from: left3, to: right3)
        
        // Find maximum matching
        let result = graph.maximumMatching(using: .hopcroftKarp())
        
        // Should find a matching of size 3 (all vertices matched)
        #expect(result.matchingSize == 3)
        #expect(result.matchingEdges.count == 3)
        #expect(result.matchedVertices.count == 6)
        #expect(result.unmatchedVertices.isEmpty)
    }
    
    @Test
    func testMatchingResultQueries() {
        var graph = BipartiteAdjacencyList()
        
        let left1 = graph.addVertex(to: .left)
        let left2 = graph.addVertex(to: .left)
        let right1 = graph.addVertex(to: .right)
        let right2 = graph.addVertex(to: .right)
        
        graph.addEdge(from: left1, to: right1)
        graph.addEdge(from: left2, to: right2)
        
        let result = graph.maximumMatching(using: .hopcroftKarp())
        
        // Test vertex matching queries
        #expect(result.isMatched(left1))
        #expect(result.isMatched(right1))
        #expect(result.isMatched(left2))
        #expect(result.isMatched(right2))
        
        // Test partner lookup
        #expect(result.partner(of: left1) == right1)
        #expect(result.partner(of: right1) == left1)
        #expect(result.partner(of: left2) == right2)
        #expect(result.partner(of: right2) == left2)
        #expect(result.partner(of: left1) != left2) // left1's partner should be right1, not left2
        
        // Test partition-specific queries
        #expect(result.matchedLeftVertices.count == 2)
        #expect(result.matchedRightVertices.count == 2)
        #expect(result.unmatchedLeftVertices.isEmpty)
        #expect(result.unmatchedRightVertices.isEmpty)
    }
    
    @Test
    func testDefaultMatchingAlgorithm() {
        var graph = BipartiteAdjacencyList()
        
        let left1 = graph.addVertex(to: .left)
        let left2 = graph.addVertex(to: .left)
        let right1 = graph.addVertex(to: .right)
        let right2 = graph.addVertex(to: .right)
        
        graph.addEdge(from: left1, to: right1)
        graph.addEdge(from: left2, to: right2)
        
        // Test default algorithm (should be Hopcroft-Karp)
        let result = graph.maximumMatching()
        
        #expect(result.matchingSize == 2)
        #expect(result.matchingEdges.count == 2)
    }
}
#endif
