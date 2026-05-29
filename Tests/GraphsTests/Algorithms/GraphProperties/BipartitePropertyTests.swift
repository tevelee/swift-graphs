import Testing
@testable import Graphs

struct BipartitePropertyTests {
    
    // MARK: - Test Graphs
    
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
    
    // MARK: - Core Behavior (BFS)
    
    @Test func emptyGraphBFS() {
        let graph = createEmptyGraph()
        #expect(graph.isBipartite(using: .bfs()))
    }
    
    @Test func singleVertexBFS() {
        let graph = createSingleVertexGraph()
        #expect(graph.isBipartite(using: .bfs()))
    }
    
    @Test func twoVertexBFS() {
        let graph = createTwoVertexGraph()
        #expect(graph.isBipartite(using: .bfs()))
    }
    
    @Test func bipartiteGraphBFS() {
        let graph = createBipartiteGraph()
        #expect(graph.isBipartite(using: .bfs()))
    }
    
    @Test func nonBipartiteGraphBFS() {
        let graph = createNonBipartiteGraph()
        #expect(!graph.isBipartite(using: .bfs()))
    }
    
    @Test func disconnectedBipartiteGraphBFS() {
        let graph = createDisconnectedBipartiteGraph()
        #expect(graph.isBipartite(using: .bfs()))
    }
    
    @Test func disconnectedNonBipartiteGraphBFS() {
        let graph = createDisconnectedNonBipartiteGraph()
        #expect(!graph.isBipartite(using: .bfs()))
    }
    
    // MARK: - Core Behavior (DFS)
    
    @Test func emptyGraphDFS() {
        let graph = createEmptyGraph()
        #expect(graph.isBipartite(using: .dfs()))
    }
    
    @Test func singleVertexDFS() {
        let graph = createSingleVertexGraph()
        #expect(graph.isBipartite(using: .dfs()))
    }
    
    @Test func twoVertexDFS() {
        let graph = createTwoVertexGraph()
        #expect(graph.isBipartite(using: .dfs()))
    }
    
    @Test func bipartiteGraphDFS() {
        let graph = createBipartiteGraph()
        #expect(graph.isBipartite(using: .dfs()))
    }
    
    @Test func nonBipartiteGraphDFS() {
        let graph = createNonBipartiteGraph()
        #expect(!graph.isBipartite(using: .dfs()))
    }
    
    @Test func disconnectedBipartiteGraphDFS() {
        let graph = createDisconnectedBipartiteGraph()
        #expect(graph.isBipartite(using: .dfs()))
    }
    
    @Test func disconnectedNonBipartiteGraphDFS() {
        let graph = createDisconnectedNonBipartiteGraph()
        #expect(!graph.isBipartite(using: .dfs()))
    }
    
    // MARK: - Algorithm Comparison
    
    @Test func bfsAndDFSConsistency() {
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
    
    // MARK: - Visitor Support
    
    @Test func bfsVisitorPattern() {
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
    
    @Test func dfsVisitorPattern() {
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
    
    @Test func graphWithSelfLoops() {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: a, to: a) { $0.label = "AA" } // Self loop
        
        // Graph with self loops cannot be bipartite
        #expect(!graph.isBipartite(using: .bfs()))
        #expect(!graph.isBipartite(using: .dfs()))
    }
    
    @Test func graphWithMultipleEdges() {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }

        graph.addEdge(from: a, to: b) { $0.label = "AB1" }
        graph.addEdge(from: a, to: b) { $0.label = "AB2" }

        // Multiple edges between same vertices - still bipartite
        #expect(graph.isBipartite(using: .bfs()))
        #expect(graph.isBipartite(using: .dfs()))
    }

    // MARK: - Composition

    /// Exercises all four `BFSBipartiteProperty.Visitor` events through a composed visitor pair.
    ///
    /// Graph: undirected triangle A−B−C (non-bipartite) triggers `colorConflict`.
    /// Both composed visitors must see identical event counts.
    @Test func bfsComposedVisitorsReceiveAllEvents() {
        let graph = createNonBipartiteGraph()  // triangle: always fires colorConflict

        var assign1 = 0;    var assign2 = 0
        var examVtx1 = 0;   var examVtx2 = 0
        var examEdge1 = 0;  var examEdge2 = 0
        var conflict1 = 0;  var conflict2 = 0

        var v1 = BFSBipartiteProperty<DefaultAdjacencyList>.Visitor()
        v1.assignColor   = { _, _ in assign1 += 1 }
        v1.examineVertex = { _ in examVtx1 += 1 }
        v1.examineEdge   = { _ in examEdge1 += 1 }
        v1.colorConflict = { _, _, _ in conflict1 += 1 }

        var v2 = BFSBipartiteProperty<DefaultAdjacencyList>.Visitor()
        v2.assignColor   = { _, _ in assign2 += 1 }
        v2.examineVertex = { _ in examVtx2 += 1 }
        v2.examineEdge   = { _ in examEdge2 += 1 }
        v2.colorConflict = { _, _, _ in conflict2 += 1 }

        let combined = v1.combined(with: v2)
        let algorithm = BFSBipartitePropertyAlgorithm<DefaultAdjacencyList>()
        let result = algorithm.isBipartite(in: graph, visitor: combined)

        #expect(!result, "triangle is not bipartite")
        #expect(assign1 >= 1,    "assignColor fires for each colored vertex")
        #expect(assign2 >= 1)
        #expect(examVtx1 >= 1,   "examineVertex fires for each dequeued vertex")
        #expect(examVtx2 >= 1)
        #expect(examEdge1 >= 1,  "examineEdge fires for each edge examined")
        #expect(examEdge2 >= 1)
        #expect(conflict1 >= 1,  "colorConflict fires when the odd cycle is detected")
        #expect(conflict2 >= 1)
        #expect(assign1 == assign2)
        #expect(examVtx1 == examVtx2)
        #expect(examEdge1 == examEdge2)
        #expect(conflict1 == conflict2)
    }

    /// Exercises all four `DFSBipartiteProperty.Visitor` events through a composed visitor pair.
    @Test func dfsComposedVisitorsReceiveAllEvents() {
        let graph = createNonBipartiteGraph()

        var assign1 = 0;    var assign2 = 0
        var examVtx1 = 0;   var examVtx2 = 0
        var examEdge1 = 0;  var examEdge2 = 0
        var conflict1 = 0;  var conflict2 = 0

        var v1 = DFSBipartiteProperty<DefaultAdjacencyList>.Visitor()
        v1.assignColor   = { _, _ in assign1 += 1 }
        v1.examineVertex = { _ in examVtx1 += 1 }
        v1.examineEdge   = { _ in examEdge1 += 1 }
        v1.colorConflict = { _, _, _ in conflict1 += 1 }

        var v2 = DFSBipartiteProperty<DefaultAdjacencyList>.Visitor()
        v2.assignColor   = { _, _ in assign2 += 1 }
        v2.examineVertex = { _ in examVtx2 += 1 }
        v2.examineEdge   = { _ in examEdge2 += 1 }
        v2.colorConflict = { _, _, _ in conflict2 += 1 }

        let combined = v1.combined(with: v2)
        let algorithm = DFSBipartitePropertyAlgorithm<DefaultAdjacencyList>()
        let result = algorithm.isBipartite(in: graph, visitor: combined)

        #expect(!result, "triangle is not bipartite")
        #expect(assign1 >= 1)
        #expect(assign2 >= 1)
        #expect(examVtx1 >= 1)
        #expect(examVtx2 >= 1)
        #expect(examEdge1 >= 1)
        #expect(examEdge2 >= 1)
        #expect(conflict1 >= 1)
        #expect(conflict2 >= 1)
        #expect(assign1 == assign2)
        #expect(examVtx1 == examVtx2)
        #expect(examEdge1 == examEdge2)
        #expect(conflict1 == conflict2)
    }
}
