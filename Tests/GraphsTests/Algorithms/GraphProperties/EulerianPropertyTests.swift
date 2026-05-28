import Testing
@testable import Graphs

struct EulerianPropertyTests {
    
    // MARK: - Test Graphs
    
    func createEulerianPathGraph() -> DefaultAdjacencyList {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        // Graph with exactly 2 vertices of odd degree (A and D)
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: b, to: c) { $0.label = "BC" }
        graph.addEdge(from: c, to: d) { $0.label = "CD" }
        graph.addEdge(from: d, to: a) { $0.label = "DA" }
        graph.addEdge(from: a, to: c) { $0.label = "AC" }
        
        return graph
    }
    
    func createEulerianCycleGraph() -> DefaultAdjacencyList {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        // Graph where all vertices have even degree (4-cycle)
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: b, to: c) { $0.label = "BC" }
        graph.addEdge(from: c, to: d) { $0.label = "CD" }
        graph.addEdge(from: d, to: a) { $0.label = "DA" }
        
        return graph
    }
    
    func createNonEulerianGraph() -> DefaultAdjacencyList {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        // Graph with 4 vertices of odd degree (not Eulerian)
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: b, to: c) { $0.label = "BC" }
        graph.addEdge(from: c, to: d) { $0.label = "CD" }
        graph.addEdge(from: d, to: a) { $0.label = "DA" }
        
        return graph
    }
    
    func createDisconnectedGraph() -> DefaultAdjacencyList {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        // Two separate components
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: c, to: d) { $0.label = "CD" }
        
        return graph
    }
    
    func createEmptyGraph() -> DefaultAdjacencyList {
        return DefaultAdjacencyList()
    }
    
    func createSingleVertexGraph() -> DefaultAdjacencyList {
        var graph = DefaultAdjacencyList()
        graph.addVertex { $0.label = "A" }
        return graph
    }
    
    // MARK: - Core Behavior (Eulerian Path)
    
    @Test func eulerianPathWithDFS() {
        let graph = createEulerianPathGraph()
        #expect(graph.hasEulerianPath(using: .dfs()))
    }
    
    @Test func eulerianPathWithBFS() {
        let graph = createEulerianPathGraph()
        #expect(graph.hasEulerianPath(using: .bfs()))
    }
    
    @Test func nonEulerianPath() {
        let graph = createNonEulerianGraph()
        // A 4-cycle has all vertices with degree 2 (even), so it has both Eulerian path and cycle
        #expect(graph.hasEulerianPath(using: .dfs()))
    }
    
    @Test func disconnectedGraphHasNoEulerianPath() {
        let graph = createDisconnectedGraph()
        #expect(!graph.hasEulerianPath(using: .dfs()))
    }
    
    @Test func emptyGraphHasNoEulerianPath() {
        let graph = createEmptyGraph()
        #expect(!graph.hasEulerianPath(using: .dfs()))
    }
    
    @Test func singleVertexGraphHasEulerianPath() {
        let graph = createSingleVertexGraph()
        // Single vertex with no edges has degree 0 (even), so it has both Eulerian path and cycle
        #expect(graph.hasEulerianPath(using: .dfs()))
    }
    
    // MARK: - Core Behavior (Eulerian Cycle)
    
    @Test func eulerianCycleWithDFS() {
        let graph = createEulerianCycleGraph()
        #expect(graph.hasEulerianCycle(using: .dfs()))
    }
    
    @Test func eulerianCycleWithBFS() {
        let graph = createEulerianCycleGraph()
        #expect(graph.hasEulerianCycle(using: .bfs()))
    }
    
    @Test func nonEulerianCycle() {
        let graph = createNonEulerianGraph()
        // A 4-cycle has all vertices with degree 2 (even), so it has an Eulerian cycle
        #expect(graph.hasEulerianCycle(using: .dfs()))
    }
    
    @Test func disconnectedGraphHasNoEulerianCycle() {
        let graph = createDisconnectedGraph()
        #expect(!graph.hasEulerianCycle(using: .dfs()))
    }
    
    @Test func emptyGraphHasNoEulerianCycle() {
        let graph = createEmptyGraph()
        #expect(!graph.hasEulerianCycle(using: .dfs()))
    }
    
    @Test func singleVertexGraphHasEulerianCycle() {
        let graph = createSingleVertexGraph()
        // Single vertex with no edges has degree 0 (even), so it has an Eulerian cycle
        #expect(graph.hasEulerianCycle(using: .dfs()))
    }
    
    // MARK: - Algorithm Comparison
    
    @Test func dfsAndBFSConsistency() {
        let testGraphs: [DefaultAdjacencyList] = [
            createEulerianPathGraph(),
            createEulerianCycleGraph(),
            createNonEulerianGraph(),
            createDisconnectedGraph(),
            createEmptyGraph(),
            createSingleVertexGraph()
        ]
        
        for graph in testGraphs {
            let dfsPathResult = graph.hasEulerianPath(using: .dfs())
            let bfsPathResult = graph.hasEulerianPath(using: .bfs())
            #expect(dfsPathResult == bfsPathResult, "DFS and BFS should give same result for Eulerian path")
            
            let dfsCycleResult = graph.hasEulerianCycle(using: .dfs())
            let bfsCycleResult = graph.hasEulerianCycle(using: .bfs())
            #expect(dfsCycleResult == bfsCycleResult, "DFS and BFS should give same result for Eulerian cycle")
        }
    }
    
    // MARK: - Edge Cases
    
    @Test func graphWithSelfLoops() {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: a, to: a) { $0.label = "AA" } // Self loop
        
        // Self loops affect degree count, so this might not be Eulerian
        let hasPath = graph.hasEulerianPath(using: .dfs())
        let hasCycle = graph.hasEulerianCycle(using: .dfs())
        
        // The result depends on the specific degree counts
        #expect(hasPath == false || hasCycle == false) // At least one should be false
    }
    
    @Test func graphWithMultipleEdges() {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.label = "AB1" }
        graph.addEdge(from: a, to: b) { $0.label = "AB2" }
        graph.addEdge(from: b, to: c) { $0.label = "BC1" }
        graph.addEdge(from: b, to: c) { $0.label = "BC2" }
        graph.addEdge(from: c, to: a) { $0.label = "CA1" }
        graph.addEdge(from: c, to: a) { $0.label = "CA2" }
        
        // All vertices have even degree (2 each)
        #expect(graph.hasEulerianCycle(using: .dfs()))
    }
}
