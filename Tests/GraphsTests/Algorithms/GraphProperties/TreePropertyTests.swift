import Testing
@testable import Graphs

struct TreePropertyTests {
    
    // MARK: - Test Cases
    
    @Test func testEmptyGraph() {
        let graph = AdjacencyList()
        #expect(graph.isTree(using: .singlePass()))
        #expect(graph.isTree(using: .dfs()))
        #expect(graph.isTree(using: .bfs()))
    }
    
    @Test func testSingleVertex() {
        var graph = AdjacencyList()
        graph.addVertex { $0.label = "1" }
        
        #expect(graph.isTree(using: .singlePass()))
        #expect(graph.isTree(using: .dfs()))
        #expect(graph.isTree(using: .bfs()))
    }
    
    @Test func testTwoVerticesConnected() {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "1" }
        let v2 = graph.addVertex { $0.label = "2" }
        graph.addEdge(from: v1, to: v2) { $0.weight = 1 }
        
        #expect(graph.isTree(using: .singlePass()))
        #expect(graph.isTree(using: .dfs()))
        #expect(graph.isTree(using: .bfs()))
    }
    
    @Test func testTwoVerticesDisconnected() {
        var graph = AdjacencyList()
        graph.addVertex { $0.label = "1" }
        graph.addVertex { $0.label = "2" }
        // No edge between them
        
        #expect(!graph.isTree(using: .singlePass()))
        #expect(!graph.isTree(using: .dfs()))
        #expect(!graph.isTree(using: .bfs()))
    }
    
    @Test func testThreeVerticesTree() {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "1" }
        let v2 = graph.addVertex { $0.label = "2" }
        let v3 = graph.addVertex { $0.label = "3" }
        graph.addEdge(from: v1, to: v2) { $0.weight = 1 }
        graph.addEdge(from: v2, to: v3) { $0.weight = 1 }
        
        #expect(graph.isTree(using: .singlePass()))
        #expect(graph.isTree(using: .dfs()))
        #expect(graph.isTree(using: .bfs()))
    }
    
    @Test func testThreeVerticesCycle() {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "1" }
        let v2 = graph.addVertex { $0.label = "2" }
        let v3 = graph.addVertex { $0.label = "3" }
        graph.addEdge(from: v1, to: v2) { $0.weight = 1 }
        graph.addEdge(from: v2, to: v3) { $0.weight = 1 }
        graph.addEdge(from: v3, to: v1) { $0.weight = 1 } // Creates a cycle
        
        #expect(!graph.isTree(using: .singlePass()))
        #expect(!graph.isTree(using: .dfs()))
        #expect(!graph.isTree(using: .bfs()))
    }
    
    @Test func testTooManyEdges() {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "1" }
        let v2 = graph.addVertex { $0.label = "2" }
        let v3 = graph.addVertex { $0.label = "3" }
        graph.addEdge(from: v1, to: v2) { $0.weight = 1 }
        graph.addEdge(from: v2, to: v3) { $0.weight = 1 }
        graph.addEdge(from: v1, to: v3) { $0.weight = 1 } // Extra edge
        
        #expect(!graph.isTree(using: .singlePass()))
        #expect(!graph.isTree(using: .dfs()))
        #expect(!graph.isTree(using: .bfs()))
    }
    
    @Test func testDisconnectedComponents() {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "1" }
        let v2 = graph.addVertex { $0.label = "2" }
        let v3 = graph.addVertex { $0.label = "3" }
        let v4 = graph.addVertex { $0.label = "4" }
        graph.addEdge(from: v1, to: v2) { $0.weight = 1 }
        graph.addEdge(from: v3, to: v4) { $0.weight = 1 }
        // Two separate components
        
        #expect(!graph.isTree(using: .singlePass()))
        #expect(!graph.isTree(using: .dfs()))
        #expect(!graph.isTree(using: .bfs()))
    }
    
    @Test func testStarGraph() {
        var graph = AdjacencyList()
        let center = graph.addVertex { $0.label = "0" }
        let v1 = graph.addVertex { $0.label = "1" }
        let v2 = graph.addVertex { $0.label = "2" }
        let v3 = graph.addVertex { $0.label = "3" }
        let v4 = graph.addVertex { $0.label = "4" }
        
        graph.addEdge(from: center, to: v1) { $0.weight = 1 }
        graph.addEdge(from: center, to: v2) { $0.weight = 1 }
        graph.addEdge(from: center, to: v3) { $0.weight = 1 }
        graph.addEdge(from: center, to: v4) { $0.weight = 1 }
        
        #expect(graph.isTree(using: .singlePass()))
        #expect(graph.isTree(using: .dfs()))
        #expect(graph.isTree(using: .bfs()))
    }
    
    @Test func testPathGraph() {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "1" }
        let v2 = graph.addVertex { $0.label = "2" }
        let v3 = graph.addVertex { $0.label = "3" }
        let v4 = graph.addVertex { $0.label = "4" }
        let v5 = graph.addVertex { $0.label = "5" }
        
        graph.addEdge(from: v1, to: v2) { $0.weight = 1 }
        graph.addEdge(from: v2, to: v3) { $0.weight = 1 }
        graph.addEdge(from: v3, to: v4) { $0.weight = 1 }
        graph.addEdge(from: v4, to: v5) { $0.weight = 1 }
        
        #expect(graph.isTree(using: .singlePass()))
        #expect(graph.isTree(using: .dfs()))
        #expect(graph.isTree(using: .bfs()))
    }
    
    @Test func testComplexCycle() {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "1" }
        let v2 = graph.addVertex { $0.label = "2" }
        let v3 = graph.addVertex { $0.label = "3" }
        let v4 = graph.addVertex { $0.label = "4" }
        let v5 = graph.addVertex { $0.label = "5" }
        
        // Create a 5-cycle
        graph.addEdge(from: v1, to: v2) { $0.weight = 1 }
        graph.addEdge(from: v2, to: v3) { $0.weight = 1 }
        graph.addEdge(from: v3, to: v4) { $0.weight = 1 }
        graph.addEdge(from: v4, to: v5) { $0.weight = 1 }
        graph.addEdge(from: v5, to: v1) { $0.weight = 1 }
        
        #expect(!graph.isTree(using: .singlePass()))
        #expect(!graph.isTree(using: .dfs()))
        #expect(!graph.isTree(using: .bfs()))
    }
    
    // MARK: - Visitor Tests
    
    @Test func testVisitorCallbacks() {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "1" }
        let v2 = graph.addVertex { $0.label = "2" }
        graph.addEdge(from: v1, to: v2) { $0.weight = 1 }
        
        let result = graph.isTree(using: .singlePass())
        
        #expect(result)
    }
    
    @Test func testVisitorCallbacksWithCycle() {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "1" }
        let v2 = graph.addVertex { $0.label = "2" }
        let v3 = graph.addVertex { $0.label = "3" }
        graph.addEdge(from: v1, to: v2) { $0.weight = 1 }
        graph.addEdge(from: v2, to: v3) { $0.weight = 1 }
        graph.addEdge(from: v3, to: v1) { $0.weight = 1 }
        
        let result = graph.isTree(using: .singlePass())
        
        #expect(!result)
    }
    
    // MARK: - Performance Tests
    
    @Test func testPerformanceLargeTree() {
        var graph = AdjacencyList()
        
        // Create a large tree (1000 vertices)
        let vertices = (0..<1000).map { i in graph.addVertex { $0.label = "\(i)" } }
        
        // Connect them in a tree structure
        for i in 1..<vertices.count {
            let parent = vertices[i / 2]
            let child = vertices[i]
            graph.addEdge(from: parent, to: child) { $0.weight = 1 }
        }
        
        let result = graph.isTree(using: .singlePass())
        #expect(result)
    }
}
