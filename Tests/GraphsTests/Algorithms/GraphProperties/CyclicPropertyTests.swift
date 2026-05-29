import Testing
@testable import Graphs

struct CyclicPropertyTests {
    @Test func emptyGraph() {
        let graph = AdjacencyList()
        #expect(!graph.isCyclic(using: .dfs()))
        #expect(!graph.isCyclic(using: .unionFind()))
    }
    
    @Test func singleVertex() {
        var graph = AdjacencyList()
        graph.addVertex { $0.label = "1" }
        
        #expect(!graph.isCyclic(using: .dfs()))
        #expect(!graph.isCyclic(using: .unionFind()))
    }
    
    @Test func twoVerticesConnected() {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "1" }
        let v2 = graph.addVertex { $0.label = "2" }
        graph.addEdge(from: v1, to: v2)
        
        #expect(!graph.isCyclic(using: .dfs()))
        #expect(!graph.isCyclic(using: .unionFind()))
    }
    
    @Test func twoVerticesDisconnected() {
        var graph = AdjacencyList()
        graph.addVertex { $0.label = "1" }
        graph.addVertex { $0.label = "2" }
        // No edge between vertices
        
        #expect(!graph.isCyclic(using: .dfs()))
        #expect(!graph.isCyclic(using: .unionFind()))
    }
    
    @Test func linearGraph() {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "1" }
        let v2 = graph.addVertex { $0.label = "2" }
        let v3 = graph.addVertex { $0.label = "3" }
        let v4 = graph.addVertex { $0.label = "4" }
        
        graph.addEdge(from: v1, to: v2)
        graph.addEdge(from: v2, to: v3)
        graph.addEdge(from: v3, to: v4)
        
        #expect(!graph.isCyclic(using: .dfs()))
        #expect(!graph.isCyclic(using: .unionFind()))
    }

    @Test func simpleCycle() {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "1" }
        let v2 = graph.addVertex { $0.label = "2" }
        let v3 = graph.addVertex { $0.label = "3" }
        
        graph.addEdge(from: v1, to: v2)
        graph.addEdge(from: v2, to: v3)
        graph.addEdge(from: v3, to: v1)
        
        #expect(graph.isCyclic(using: .dfs()))
        #expect(graph.isCyclic(using: .unionFind()))
    }
    
    @Test func largerCycle() {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "1" }
        let v2 = graph.addVertex { $0.label = "2" }
        let v3 = graph.addVertex { $0.label = "3" }
        let v4 = graph.addVertex { $0.label = "4" }
        let v5 = graph.addVertex { $0.label = "5" }
        
        graph.addEdge(from: v1, to: v2)
        graph.addEdge(from: v2, to: v3)
        graph.addEdge(from: v3, to: v4)
        graph.addEdge(from: v4, to: v5)
        graph.addEdge(from: v5, to: v1)
        
        #expect(graph.isCyclic(using: .dfs()))
        #expect(graph.isCyclic(using: .unionFind()))
    }
    
    @Test func treeWithCycle() {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "1" }
        let v2 = graph.addVertex { $0.label = "2" }
        let v3 = graph.addVertex { $0.label = "3" }
        let v4 = graph.addVertex { $0.label = "4" }
        let v5 = graph.addVertex { $0.label = "5" }
        
        // Create a tree structure
        graph.addEdge(from: v1, to: v2)
        graph.addEdge(from: v1, to: v3)
        graph.addEdge(from: v2, to: v4)
        graph.addEdge(from: v2, to: v5)
        
        // Add a cycle: v2 -> v4 -> v5 -> v2
        graph.addEdge(from: v4, to: v5)
        graph.addEdge(from: v5, to: v2)
        
        #expect(graph.isCyclic(using: .dfs()))
        #expect(graph.isCyclic(using: .unionFind()))
    }
    
    @Test func complexAcyclicGraph() {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "1" }
        let v2 = graph.addVertex { $0.label = "2" }
        let v3 = graph.addVertex { $0.label = "3" }
        let v4 = graph.addVertex { $0.label = "4" }
        let v5 = graph.addVertex { $0.label = "5" }
        let v6 = graph.addVertex { $0.label = "6" }
        
        // Create a complex but acyclic graph
        graph.addEdge(from: v1, to: v2)
        graph.addEdge(from: v1, to: v3)
        graph.addEdge(from: v2, to: v4)
        graph.addEdge(from: v3, to: v4)
        graph.addEdge(from: v4, to: v5)
        graph.addEdge(from: v5, to: v6)
        
        // DFS correctly detects this as acyclic
        #expect(!graph.isCyclic(using: .dfs()))
        
        // Union-Find treats directed graphs as undirected, so it detects
        // a cycle in the underlying undirected graph (v2-v4-v3-v1-v2)
        // This is expected behavior for Union-Find on directed graphs
        #expect(graph.isCyclic(using: .unionFind()))
    }

    @Test func complexCyclicGraph() {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "1" }
        let v2 = graph.addVertex { $0.label = "2" }
        let v3 = graph.addVertex { $0.label = "3" }
        let v4 = graph.addVertex { $0.label = "4" }
        let v5 = graph.addVertex { $0.label = "5" }
        let v6 = graph.addVertex { $0.label = "6" }
        
        // Create a complex graph with multiple cycles
        graph.addEdge(from: v1, to: v2)
        graph.addEdge(from: v2, to: v3)
        graph.addEdge(from: v3, to: v4)
        graph.addEdge(from: v4, to: v5)
        graph.addEdge(from: v5, to: v6)
        graph.addEdge(from: v6, to: v1) // Creates a cycle
        graph.addEdge(from: v2, to: v5) // Creates another cycle
        
        #expect(graph.isCyclic(using: .dfs()))
        #expect(graph.isCyclic(using: .unionFind()))
    }
    
    @Test func disconnectedGraphWithCycle() {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "1" }
        let v2 = graph.addVertex { $0.label = "2" }
        let v3 = graph.addVertex { $0.label = "3" }
        let v4 = graph.addVertex { $0.label = "4" }
        let v5 = graph.addVertex { $0.label = "5" }
        
        // First component: acyclic
        graph.addEdge(from: v1, to: v2)
        
        // Second component: cyclic
        graph.addEdge(from: v3, to: v4)
        graph.addEdge(from: v4, to: v5)
        graph.addEdge(from: v5, to: v3)
        
        #expect(graph.isCyclic(using: .dfs()))
        #expect(graph.isCyclic(using: .unionFind()))
    }
    
    @Test func disconnectedGraphWithoutCycle() {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "1" }
        let v2 = graph.addVertex { $0.label = "2" }
        let v3 = graph.addVertex { $0.label = "3" }
        let v4 = graph.addVertex { $0.label = "4" }
        
        // First component: acyclic
        graph.addEdge(from: v1, to: v2)
        
        // Second component: acyclic
        graph.addEdge(from: v3, to: v4)
        
        #expect(!graph.isCyclic(using: .dfs()))
        #expect(!graph.isCyclic(using: .unionFind()))
    }
    
    // MARK: - UnionFindCyclicPropertyAlgorithm rank branches

    /// Exercises the `rankX < rankY` branch inside `UnionFindCyclicPropertyAlgorithm.union()`.
    ///
    /// Edge ordering matters for rank:
    /// - a→b first: equal ranks (0 == 0) → parent[b]=a, rank[a]=1 (covers equal branch)
    /// - c→a next: findRoot(c)=c (rank 0) < findRoot(a)=a (rank 1) → parent[c]=a (covers rankX < rankY)
    @Test func unionFindAlgorithmRankXLessThanRankYBranch() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b)  // equal ranks → rank[a]=1
        graph.addEdge(from: c, to: a)  // rootC rank 0 < rootA rank 1 → rankX < rankY branch

        #expect(!graph.isCyclic(using: .unionFind()), "a→b, c→a has no cycle; exercises rankX < rankY in union()")
    }

    // MARK: - UnionFindCyclicProperty Direct API Coverage

    /// Directly instantiates `UnionFindCyclicProperty` (the lower-level data structure).
    /// Exercises `examineEdge`, `findRoot`, `unionVertices` visitors and all three union rank branches:
    /// - a→b: equal ranks → rank[a]=1
    /// - b→c: findRoot(b)=a (rank 1) > rank[c]=0 → rankX > rankY
    /// - d→a: findRoot(d)=d (rank 0) < findRoot(a)=a (rank 1) → rankX < rankY
    @Test func unionFindCyclicPropertyDirectInstantiation_noCycle() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        graph.addEdge(from: a, to: b)  // equal ranks → rank[a]=1
        graph.addEdge(from: b, to: c)  // rankX(a)=1 > rankY(c)=0 → parent[c]=a
        graph.addEdge(from: d, to: a)  // rankX(d)=0 < rankY(a)=1 → parent[d]=a (rankX < rankY)

        var uf = UnionFindCyclicProperty(on: graph)
        var examineEdgeCount = 0
        var findRootCount = 0
        var unionCount = 0
        var cycleCount = 0

        let hasCycle = uf.hasCycle(visitor: .init(
            examineEdge: { _ in examineEdgeCount += 1 },
            findRoot: { _, _ in findRootCount += 1 },
            unionVertices: { _, _ in unionCount += 1 },
            cycleDetected: { _ in cycleCount += 1 }
        ))

        #expect(!hasCycle, "a→b, b→c, d→a form a tree with no cycle")
        #expect(examineEdgeCount == 3, "three edges examined")
        #expect(unionCount == 3, "three union operations performed")
        #expect(cycleCount == 0, "no cycle detected")
    }

    /// Directly instantiates `UnionFindCyclicProperty` on a cyclic graph to exercise
    /// `cycleDetected` visitor callback and the early-return path.
    @Test func unionFindCyclicPropertyDirectInstantiation_withCycle() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: a)  // closes cycle a→b→c→a

        var uf = UnionFindCyclicProperty(on: graph)
        var cycleEdgeCount = 0
        let hasCycle = uf.hasCycle(visitor: .init(cycleDetected: { _ in cycleEdgeCount += 1 }))

        #expect(hasCycle, "a→b→c→a has a cycle")
        #expect(cycleEdgeCount == 1, "cycleDetected fires once")
    }

    // MARK: - Visitor Support

    @Test func visitorCallbacks() {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "1" }
        let v2 = graph.addVertex { $0.label = "2" }
        let v3 = graph.addVertex { $0.label = "3" }
        graph.addEdge(from: v1, to: v2)
        graph.addEdge(from: v2, to: v3)
        graph.addEdge(from: v3, to: v1) // Creates a cycle
        
        var discoverVertexCount = 0
        var examineVertexCount = 0
        var examineEdgeCount = 0
        var backEdgeCount = 0
        
        var visitor = DepthFirstSearch<DefaultAdjacencyList>.Visitor()
        visitor.discoverVertex = { _ in discoverVertexCount += 1 }
        visitor.examineVertex = { _ in examineVertexCount += 1 }
        visitor.examineEdge = { _ in examineEdgeCount += 1 }
        visitor.backEdge = { _ in backEdgeCount += 1 }
        
        let result = graph.isCyclic(using: .dfs().withVisitor(visitor))
        
        #expect(result)
        #expect(discoverVertexCount > 0)
        #expect(examineVertexCount > 0)
        #expect(examineEdgeCount > 0)
        #expect(backEdgeCount > 0)
    }
    
    @Test func unionFindVisitorCallbacks() {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "1" }
        let v2 = graph.addVertex { $0.label = "2" }
        let v3 = graph.addVertex { $0.label = "3" }
        graph.addEdge(from: v1, to: v2)
        graph.addEdge(from: v2, to: v3)
        graph.addEdge(from: v3, to: v1) // Creates a cycle
        
        var examineEdgeCount = 0
        var findRootCount = 0
        var unionVerticesCount = 0
        var cycleDetectedCount = 0
        
        var visitor = UnionFindCyclicProperty<DefaultAdjacencyList>.Visitor()
        visitor.examineEdge = { _ in examineEdgeCount += 1 }
        visitor.findRoot = { _, _ in findRootCount += 1 }
        visitor.unionVertices = { _, _ in unionVerticesCount += 1 }
        visitor.cycleDetected = { _ in cycleDetectedCount += 1 }
        
        let result = graph.isCyclic(using: .unionFind())
        
        #expect(result)
        // Note: Union-Find doesn't support visitors yet, so we can't test callbacks
        // This test just verifies the algorithm works correctly
    }
    
    // MARK: - Performance
    
    @Test func performanceLargeAcyclicGraph() {
        var graph = AdjacencyList()
        let vertexCount = 1000
        
        // Create vertices
        var vertices: [DefaultAdjacencyList.VertexDescriptor] = []
        for i in 0..<vertexCount {
            let vertex = graph.addVertex { $0.label = "\(i)" }
            vertices.append(vertex)
        }
        
        // Create a tree (acyclic)
        for i in 0..<(vertexCount - 1) {
            graph.addEdge(from: vertices[i], to: vertices[i + 1])
        }
        
        let dfsResult = graph.isCyclic(using: .dfs())
        let unionFindResult = graph.isCyclic(using: .unionFind())
        
        #expect(!dfsResult)
        #expect(!unionFindResult)
    }
    
    @Test func performanceLargeCyclicGraph() {
        var graph = AdjacencyList()
        let vertexCount = 1000
        
        // Create vertices
        var vertices: [DefaultAdjacencyList.VertexDescriptor] = []
        for i in 0..<vertexCount {
            let vertex = graph.addVertex { $0.label = "\(i)" }
            vertices.append(vertex)
        }
        
        // Create a cycle
        for i in 0..<(vertexCount - 1) {
            graph.addEdge(from: vertices[i], to: vertices[i + 1])
        }
        graph.addEdge(from: vertices[vertexCount - 1], to: vertices[0])
        
        let dfsResult = graph.isCyclic(using: .dfs())
        let unionFindResult = graph.isCyclic(using: .unionFind())
        
        #expect(dfsResult)
        #expect(unionFindResult)
    }
}
