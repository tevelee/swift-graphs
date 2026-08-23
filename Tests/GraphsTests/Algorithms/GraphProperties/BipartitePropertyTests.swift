import Testing

@testable import Graphs

struct BipartitePropertyTests {

    // MARK: - Test Graphs

    func createBipartiteGraph() -> AdjacencyList {
        var graph = AdjacencyList()
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

    func createNonBipartiteGraph() -> AdjacencyList {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }

        // Create triangle (odd cycle) - not bipartite
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: b, to: c) { $0.label = "BC" }
        graph.addEdge(from: c, to: a) { $0.label = "CA" }

        return graph
    }

    func createEmptyGraph() -> AdjacencyList {
        return AdjacencyList()
    }

    func createSingleVertexGraph() -> AdjacencyList {
        var graph = AdjacencyList()
        graph.addVertex { $0.label = "A" }
        return graph
    }

    func createTwoVertexGraph() -> AdjacencyList {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        return graph
    }

    func createDisconnectedBipartiteGraph() -> AdjacencyList {
        var graph = AdjacencyList()
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

    func createDisconnectedNonBipartiteGraph() -> AdjacencyList {
        var graph = AdjacencyList()
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
        let testGraphs: [AdjacencyList] = [
            createEmptyGraph(),
            createSingleVertexGraph(),
            createTwoVertexGraph(),
            createBipartiteGraph(),
            createNonBipartiteGraph(),
            createDisconnectedBipartiteGraph(),
            createDisconnectedNonBipartiteGraph(),
        ]

        for graph in testGraphs {
            let bfsResult = graph.isBipartite(using: .bfs())
            let dfsResult = graph.isBipartite(using: .dfs())
            #expect(bfsResult == dfsResult, "BFS and DFS should give same result for graph")
        }
    }

    // MARK: - Observation Support

    @Test func bfsObservationPattern() {
        let graph = createBipartiteGraph()
        var colorAssignments: [(String, Int)] = []
        var colorConflicts: [(String, String, Int)] = []

        typealias Cases = BFSBipartitePropertyAlgorithm<AdjacencyList>.EventCases
        let algorithm = BFSBipartitePropertyAlgorithm<AdjacencyList>()
            .observing(Cases.colorAssigned) { assignment in
                // Get vertex label by finding the vertex in the graph
                for vertex in graph.vertices() where vertex == assignment.vertex {
                    colorAssignments.append(("Vertex", assignment.color))
                    break
                }
            }
            .observing(Cases.colorConflictDetected) { conflict in
                colorConflicts.append(("Vertex1", "Vertex2", conflict.color))
            }

        let result = graph.isBipartite(using: algorithm)

        #expect(result == true)
        #expect(colorConflicts.isEmpty)
        #expect(!colorAssignments.isEmpty)
    }

    @Test func dfsObservationPattern() {
        let graph = createNonBipartiteGraph()
        var colorAssignments: [(String, Int)] = []
        var colorConflicts: [(String, String, Int)] = []

        typealias Cases = DFSBipartitePropertyAlgorithm<AdjacencyList>.EventCases
        let algorithm = DFSBipartitePropertyAlgorithm<AdjacencyList>()
            .observing(Cases.colorAssigned) { assignment in
                // Get vertex label by finding the vertex in the graph
                for vertex in graph.vertices() where vertex == assignment.vertex {
                    colorAssignments.append(("Vertex", assignment.color))
                    break
                }
            }
            .observing(Cases.colorConflictDetected) { conflict in
                colorConflicts.append(("Vertex1", "Vertex2", conflict.color))
            }

        let result = graph.isBipartite(using: algorithm)

        #expect(result == false)
        #expect(!colorConflicts.isEmpty)
    }

    // MARK: - Edge Cases

    @Test func graphWithSelfLoops() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }

        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: a, to: a) { $0.label = "AA" }  // Self loop

        // Graph with self loops cannot be bipartite
        #expect(!graph.isBipartite(using: .bfs()))
        #expect(!graph.isBipartite(using: .dfs()))
    }

    @Test func graphWithMultipleEdges() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }

        graph.addEdge(from: a, to: b) { $0.label = "AB1" }
        graph.addEdge(from: a, to: b) { $0.label = "AB2" }

        // Multiple edges between same vertices - still bipartite
        #expect(graph.isBipartite(using: .bfs()))
        #expect(graph.isBipartite(using: .dfs()))
    }

    // MARK: - Composition

    /// Exercises all four BFS bipartite events through two composed observation groups.
    ///
    /// Graph: undirected triangle A−B−C (non-bipartite) emits `colorConflictDetected`.
    /// Both composed observation groups must see identical event counts.
    @Test func bfsComposedObservationsReceiveAllEvents() {
        let graph = createNonBipartiteGraph()  // triangle always emits colorConflictDetected

        var assign1 = 0
        var assign2 = 0
        var examVtx1 = 0
        var examVtx2 = 0
        var examEdge1 = 0
        var examEdge2 = 0
        var conflict1 = 0
        var conflict2 = 0

        typealias Cases = BFSBipartitePropertyAlgorithm<AdjacencyList>.EventCases
        let observed = BFSBipartitePropertyAlgorithm<AdjacencyList>()
            .observing(Cases.colorAssigned) { _ in assign1 += 1 }
            .observing(Cases.vertexExamined) { _ in examVtx1 += 1 }
            .observing(Cases.edgeExamined) { _ in examEdge1 += 1 }
            .observing(Cases.colorConflictDetected) { _ in conflict1 += 1 }
            .observing(Cases.colorAssigned) { _ in assign2 += 1 }
            .observing(Cases.vertexExamined) { _ in examVtx2 += 1 }
            .observing(Cases.edgeExamined) { _ in examEdge2 += 1 }
            .observing(Cases.colorConflictDetected) { _ in conflict2 += 1 }
        let result = graph.isBipartite(using: observed)

        #expect(!result, "triangle is not bipartite")
        #expect(assign1 >= 1, "colorAssigned fires for each colored vertex")
        #expect(assign2 >= 1)
        #expect(examVtx1 >= 1, "vertexExamined fires for each dequeued vertex")
        #expect(examVtx2 >= 1)
        #expect(examEdge1 >= 1, "edgeExamined fires for each examined edge")
        #expect(examEdge2 >= 1)
        #expect(conflict1 >= 1, "colorConflictDetected fires when the odd cycle is detected")
        #expect(conflict2 >= 1)
        #expect(assign1 == assign2)
        #expect(examVtx1 == examVtx2)
        #expect(examEdge1 == examEdge2)
        #expect(conflict1 == conflict2)
    }

    /// Exercises all four DFS bipartite events through two composed observation groups.
    @Test func dfsComposedObservationsReceiveAllEvents() {
        let graph = createNonBipartiteGraph()

        var assign1 = 0
        var assign2 = 0
        var examVtx1 = 0
        var examVtx2 = 0
        var examEdge1 = 0
        var examEdge2 = 0
        var conflict1 = 0
        var conflict2 = 0

        typealias Cases = DFSBipartitePropertyAlgorithm<AdjacencyList>.EventCases
        let observed = DFSBipartitePropertyAlgorithm<AdjacencyList>()
            .observing(Cases.colorAssigned) { _ in assign1 += 1 }
            .observing(Cases.vertexExamined) { _ in examVtx1 += 1 }
            .observing(Cases.edgeExamined) { _ in examEdge1 += 1 }
            .observing(Cases.colorConflictDetected) { _ in conflict1 += 1 }
            .observing(Cases.colorAssigned) { _ in assign2 += 1 }
            .observing(Cases.vertexExamined) { _ in examVtx2 += 1 }
            .observing(Cases.edgeExamined) { _ in examEdge2 += 1 }
            .observing(Cases.colorConflictDetected) { _ in conflict2 += 1 }
        let result = graph.isBipartite(using: observed)

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
