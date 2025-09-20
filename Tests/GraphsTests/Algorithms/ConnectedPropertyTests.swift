import Testing
@testable import Graphs

// MARK: - Test Cases

@Test func testEmptyGraph() {
    let graph = AdjacencyList()
    #expect(graph.isConnected(using: .dfs()))
    #expect(graph.isConnected(using: .bfs()))
}

@Test func testSingleVertex() {
    var graph = AdjacencyList()
    _ = graph.addVertex { $0.label = "1" }
    
    #expect(graph.isConnected(using: .dfs()))
    #expect(graph.isConnected(using: .bfs()))
}

@Test func testTwoVerticesConnected() {
    var graph = AdjacencyList()
    let v1 = graph.addVertex { $0.label = "1" }
    let v2 = graph.addVertex { $0.label = "2" }
    _ = graph.addEdge(from: v1, to: v2)
    
    #expect(graph.isConnected(using: .dfs()))
    #expect(graph.isConnected(using: .bfs()))
}

@Test func testTwoVerticesDisconnected() {
    var graph = AdjacencyList()
    _ = graph.addVertex { $0.label = "1" }
    _ = graph.addVertex { $0.label = "2" }
    // No edge between vertices
    
    #expect(!graph.isConnected(using: .dfs()))
    #expect(!graph.isConnected(using: .bfs()))
}

@Test func testLinearGraph() {
    var graph = AdjacencyList()
    let v1 = graph.addVertex { $0.label = "1" }
    let v2 = graph.addVertex { $0.label = "2" }
    let v3 = graph.addVertex { $0.label = "3" }
    let v4 = graph.addVertex { $0.label = "4" }
    
    _ = graph.addEdge(from: v1, to: v2)
    _ = graph.addEdge(from: v2, to: v3)
    _ = graph.addEdge(from: v3, to: v4)
    
    #expect(graph.isConnected(using: .dfs()))
    #expect(graph.isConnected(using: .bfs()))
}

@Test func testStarGraph() {
    var graph = AdjacencyList()
    let center = graph.addVertex { $0.label = "0" }
    let v1 = graph.addVertex { $0.label = "1" }
    let v2 = graph.addVertex { $0.label = "2" }
    let v3 = graph.addVertex { $0.label = "3" }
    
    _ = graph.addEdge(from: center, to: v1)
    _ = graph.addEdge(from: center, to: v2)
    _ = graph.addEdge(from: center, to: v3)
    
    #expect(graph.isConnected(using: .dfs()))
    #expect(graph.isConnected(using: .bfs()))
}

@Test func testCycleGraph() {
    var graph = AdjacencyList()
    let v1 = graph.addVertex { $0.label = "1" }
    let v2 = graph.addVertex { $0.label = "2" }
    let v3 = graph.addVertex { $0.label = "3" }
    let v4 = graph.addVertex { $0.label = "4" }
    
    _ = graph.addEdge(from: v1, to: v2)
    _ = graph.addEdge(from: v2, to: v3)
    _ = graph.addEdge(from: v3, to: v4)
    _ = graph.addEdge(from: v4, to: v1)
    
    #expect(graph.isConnected(using: .dfs()))
    #expect(graph.isConnected(using: .bfs()))
}

@Test func testDisconnectedGraph() {
    var graph = AdjacencyList()
    let v1 = graph.addVertex { $0.label = "1" }
    let v2 = graph.addVertex { $0.label = "2" }
    let v3 = graph.addVertex { $0.label = "3" }
    let v4 = graph.addVertex { $0.label = "4" }
    
    // First component: v1-v2
    _ = graph.addEdge(from: v1, to: v2)
    
    // Second component: v3-v4
    _ = graph.addEdge(from: v3, to: v4)
    
    #expect(!graph.isConnected(using: .dfs()))
    #expect(!graph.isConnected(using: .bfs()))
}

@Test func testComplexConnectedGraph() {
    var graph = AdjacencyList()
    let v1 = graph.addVertex { $0.label = "1" }
    let v2 = graph.addVertex { $0.label = "2" }
    let v3 = graph.addVertex { $0.label = "3" }
    let v4 = graph.addVertex { $0.label = "4" }
    let v5 = graph.addVertex { $0.label = "5" }
    let v6 = graph.addVertex { $0.label = "6" }
    
    // Create a complex but connected graph
    _ = graph.addEdge(from: v1, to: v2)
    _ = graph.addEdge(from: v1, to: v3)
    _ = graph.addEdge(from: v2, to: v4)
    _ = graph.addEdge(from: v3, to: v4)
    _ = graph.addEdge(from: v4, to: v5)
    _ = graph.addEdge(from: v5, to: v6)
    _ = graph.addEdge(from: v6, to: v1)
    
    #expect(graph.isConnected(using: .dfs()))
    #expect(graph.isConnected(using: .bfs()))
}

@Test func testComplexDisconnectedGraph() {
    var graph = AdjacencyList()
    let v1 = graph.addVertex { $0.label = "1" }
    let v2 = graph.addVertex { $0.label = "2" }
    let v3 = graph.addVertex { $0.label = "3" }
    let v4 = graph.addVertex { $0.label = "4" }
    let v5 = graph.addVertex { $0.label = "5" }
    let v6 = graph.addVertex { $0.label = "6" }
    
    // First component: v1-v2-v3
    _ = graph.addEdge(from: v1, to: v2)
    _ = graph.addEdge(from: v2, to: v3)
    
    // Second component: v4-v5-v6
    _ = graph.addEdge(from: v4, to: v5)
    _ = graph.addEdge(from: v5, to: v6)
    
    #expect(!graph.isConnected(using: .dfs()))
    #expect(!graph.isConnected(using: .bfs()))
}

// MARK: - Visitor Tests

@Test func testVisitorCallbacks() {
    var graph = AdjacencyList()
    let v1 = graph.addVertex { $0.label = "1" }
    let v2 = graph.addVertex { $0.label = "2" }
    let v3 = graph.addVertex { $0.label = "3" }
    _ = graph.addEdge(from: v1, to: v2)
    _ = graph.addEdge(from: v2, to: v3)
    
    var discoverVertexCount = 0
    var examineVertexCount = 0
    var examineEdgeCount = 0
    
    var visitor = DFSTraversal<DefaultAdjacencyList>.Visitor()
    visitor.discoverVertex = { _ in discoverVertexCount += 1 }
    visitor.examineVertex = { _ in examineVertexCount += 1 }
    visitor.examineEdge = { _ in examineEdgeCount += 1 }
    
    let result = graph.isConnected(using: .dfs().withVisitor(visitor))
    
    #expect(result)
    #expect(discoverVertexCount == 3) // All 3 vertices discovered
    #expect(examineVertexCount > 0)
    #expect(examineEdgeCount > 0)
}

// MARK: - Performance Tests

@Test func testPerformanceLargeConnectedGraph() {
    var graph = AdjacencyList()
    let vertexCount = 1000
    
    // Create vertices
    var vertices: [DefaultAdjacencyList.VertexDescriptor] = []
    for i in 0..<vertexCount {
        let vertex = graph.addVertex { $0.label = "\(i)" }
        vertices.append(vertex)
    }
    
    // Create a connected graph (linear chain)
    for i in 0..<(vertexCount - 1) {
        _ = graph.addEdge(from: vertices[i], to: vertices[i + 1])
    }
    
    // Note: Swift Testing doesn't have a direct equivalent to XCTest's measure
    // We'll just run the tests to ensure they complete
    let dfsResult = graph.isConnected(using: .dfs())
    let bfsResult = graph.isConnected(using: .bfs())
    
    #expect(dfsResult)
    #expect(bfsResult)
}

@Test func testPerformanceLargeDisconnectedGraph() {
    var graph = AdjacencyList()
    let vertexCount = 1000
    
    // Create vertices
    var vertices: [DefaultAdjacencyList.VertexDescriptor] = []
    for i in 0..<vertexCount {
        let vertex = graph.addVertex { $0.label = "\(i)" }
        vertices.append(vertex)
    }
    
    // Create two separate components
    let halfCount = vertexCount / 2
    for i in 0..<(halfCount - 1) {
        _ = graph.addEdge(from: vertices[i], to: vertices[i + 1])
    }
    for i in halfCount..<(vertexCount - 1) {
        _ = graph.addEdge(from: vertices[i], to: vertices[i + 1])
    }
    
    // Note: Swift Testing doesn't have a direct equivalent to XCTest's measure
    // We'll just run the tests to ensure they complete
    let dfsResult = graph.isConnected(using: .dfs())
    let bfsResult = graph.isConnected(using: .bfs())
    
    #expect(!dfsResult)
    #expect(!bfsResult)
}
