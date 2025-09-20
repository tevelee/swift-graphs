import Testing
@testable import Graphs

struct BipartitePropertyTests {
    
    // MARK: - Test Data Creation
    
    func createBipartiteGraph() -> DefaultAdjacencyList {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        // Create bipartite graph: {A, C} <-> {B, D}
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: a, to: d) { $0.label = "AD" }
        graph.addEdge(from: c, to: b) { $0.label = "CB" }
        graph.addEdge(from: c, to: d) { $0.label = "CD" }
        
        return graph
    }
    
    func createNonBipartiteGraph() -> DefaultAdjacencyList {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        // Create triangle (odd cycle) - not bipartite
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: b, to: c) { $0.label = "BC" }
        graph.addEdge(from: c, to: a) { $0.label = "CA" }
        
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
    
    func createTwoVertexGraph() -> DefaultAdjacencyList {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        return graph
    }
    
    func createDisconnectedBipartiteGraph() -> DefaultAdjacencyList {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }
        let f = graph.addVertex { $0.label = "F" }
        
        // First component: {A, C} <-> {B, D}
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: c, to: d) { $0.label = "CD" }
        
        // Second component: {E} <-> {F}
        graph.addEdge(from: e, to: f) { $0.label = "EF" }
        
        return graph
    }
    
    func createDisconnectedNonBipartiteGraph() -> DefaultAdjacencyList {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }
        
        // First component: bipartite {A} <-> {B}
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        
        // Second component: non-bipartite triangle {C, D, E}
        graph.addEdge(from: c, to: d) { $0.label = "CD" }
        graph.addEdge(from: d, to: e) { $0.label = "DE" }
        graph.addEdge(from: e, to: c) { $0.label = "EC" }
        
        return graph
    }
    
    // MARK: - BFS Algorithm Tests
    
    @Test func testEmptyGraphBFS() {
        let graph = createEmptyGraph()
        #expect(graph.isBipartite(using: .bfs()))
    }
    
    @Test func testSingleVertexBFS() {
        let graph = createSingleVertexGraph()
        #expect(graph.isBipartite(using: .bfs()))
    }
    
    @Test func testTwoVertexBFS() {
        let graph = createTwoVertexGraph()
        #expect(graph.isBipartite(using: .bfs()))
    }
    
    @Test func testBipartiteGraphBFS() {
        let graph = createBipartiteGraph()
        #expect(graph.isBipartite(using: .bfs()))
    }
    
    @Test func testNonBipartiteGraphBFS() {
        let graph = createNonBipartiteGraph()
        #expect(!graph.isBipartite(using: .bfs()))
    }
    
    @Test func testDisconnectedBipartiteGraphBFS() {
        let graph = createDisconnectedBipartiteGraph()
        #expect(graph.isBipartite(using: .bfs()))
    }
    
    @Test func testDisconnectedNonBipartiteGraphBFS() {
        let graph = createDisconnectedNonBipartiteGraph()
        #expect(!graph.isBipartite(using: .bfs()))
    }
    
    // MARK: - DFS Algorithm Tests
    
    @Test func testEmptyGraphDFS() {
        let graph = createEmptyGraph()
        #expect(graph.isBipartite(using: .dfs()))
    }
    
    @Test func testSingleVertexDFS() {
        let graph = createSingleVertexGraph()
        #expect(graph.isBipartite(using: .dfs()))
    }
    
    @Test func testTwoVertexDFS() {
        let graph = createTwoVertexGraph()
        #expect(graph.isBipartite(using: .dfs()))
    }
    
    @Test func testBipartiteGraphDFS() {
        let graph = createBipartiteGraph()
        #expect(graph.isBipartite(using: .dfs()))
    }
    
    @Test func testNonBipartiteGraphDFS() {
        let graph = createNonBipartiteGraph()
        #expect(!graph.isBipartite(using: .dfs()))
    }
    
    @Test func testDisconnectedBipartiteGraphDFS() {
        let graph = createDisconnectedBipartiteGraph()
        #expect(graph.isBipartite(using: .dfs()))
    }
    
    @Test func testDisconnectedNonBipartiteGraphDFS() {
        let graph = createDisconnectedNonBipartiteGraph()
        #expect(!graph.isBipartite(using: .dfs()))
    }
    
    // MARK: - Algorithm Consistency Tests
    
    @Test func testBFSAndDFSConsistency() {
        let testGraphs: [DefaultAdjacencyList] = [
            createEmptyGraph(),
            createSingleVertexGraph(),
            createTwoVertexGraph(),
            createBipartiteGraph(),
            createNonBipartiteGraph(),
            createDisconnectedBipartiteGraph(),
            createDisconnectedNonBipartiteGraph()
        ]
        
        for graph in testGraphs {
            let bfsResult = graph.isBipartite(using: .bfs())
            let dfsResult = graph.isBipartite(using: .dfs())
            #expect(bfsResult == dfsResult, "BFS and DFS should give same result for graph")
        }
    }
    
    // MARK: - Visitor Pattern Tests
    
    @Test func testBFSVisitorPattern() {
        let graph = createBipartiteGraph()
        var colorAssignments: [(String, Int)] = []
        var colorConflicts: [(String, String, Int)] = []
        
        let visitor = BFSBipartiteProperty<DefaultAdjacencyList>.Visitor(
            assignColor: { vertex, color in
                // Get vertex label by finding the vertex in the graph
                for v in graph.vertices() {
                    if v == vertex {
                        colorAssignments.append(("Vertex", color))
                        break
                    }
                }
            },
            colorConflict: { vertex1, vertex2, color in
                colorConflicts.append(("Vertex1", "Vertex2", color))
            }
        )
        
        let algorithm = BFSBipartitePropertyAlgorithm<DefaultAdjacencyList>()
        let result = algorithm.isBipartite(in: graph, visitor: visitor)
        
        #expect(result == true)
        #expect(colorConflicts.isEmpty)
        #expect(!colorAssignments.isEmpty)
    }
    
    @Test func testDFSVisitorPattern() {
        let graph = createNonBipartiteGraph()
        var colorAssignments: [(String, Int)] = []
        var colorConflicts: [(String, String, Int)] = []
        
        let visitor = DFSBipartiteProperty<DefaultAdjacencyList>.Visitor(
            assignColor: { vertex, color in
                // Get vertex label by finding the vertex in the graph
                for v in graph.vertices() {
                    if v == vertex {
                        colorAssignments.append(("Vertex", color))
                        break
                    }
                }
            },
            colorConflict: { vertex1, vertex2, color in
                colorConflicts.append(("Vertex1", "Vertex2", color))
            }
        )
        
        let algorithm = DFSBipartitePropertyAlgorithm<DefaultAdjacencyList>()
        let result = algorithm.isBipartite(in: graph, visitor: visitor)
        
        #expect(result == false)
        #expect(!colorConflicts.isEmpty)
    }
    
    // MARK: - Edge Cases
    
    @Test func testGraphWithSelfLoops() {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: a, to: a) { $0.label = "AA" } // Self loop
        
        // Graph with self loops cannot be bipartite
        #expect(!graph.isBipartite(using: .bfs()))
        #expect(!graph.isBipartite(using: .dfs()))
    }
    
    @Test func testGraphWithMultipleEdges() {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        
        graph.addEdge(from: a, to: b) { $0.label = "AB1" }
        graph.addEdge(from: a, to: b) { $0.label = "AB2" }
        
        // Multiple edges between same vertices - still bipartite
        #expect(graph.isBipartite(using: .bfs()))
        #expect(graph.isBipartite(using: .dfs()))
    }
}
