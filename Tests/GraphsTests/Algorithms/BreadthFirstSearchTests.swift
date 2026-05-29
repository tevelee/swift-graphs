@testable import Graphs
import Testing

struct BreadthFirstSearchTests {

    // MARK: - Test Graphs

    func createMultiLevelTreeGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        
        let root = graph.addVertex { $0.label = "root" }
        let a = graph.addVertex { $0.label = "a" }
        let b = graph.addVertex { $0.label = "b" }
        let c = graph.addVertex { $0.label = "c" }
        let x = graph.addVertex { $0.label = "x" }
        let y = graph.addVertex { $0.label = "y" }
        let z = graph.addVertex { $0.label = "z" }
        
        graph.addEdge(from: root, to: a)
        graph.addEdge(from: root, to: b)
        graph.addEdge(from: root, to: c)
        graph.addEdge(from: a, to: x)
        graph.addEdge(from: a, to: y)
        graph.addEdge(from: a, to: z)
        
        return graph
    }
    
    func createSimpleTreeGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        
        let root = graph.addVertex { $0.label = "root" }
        let a = graph.addVertex { $0.label = "a" }
        let b = graph.addVertex { $0.label = "b" }
        let c = graph.addVertex { $0.label = "c" }
        let d = graph.addVertex { $0.label = "d" }
        
        graph.addEdge(from: root, to: a)
        graph.addEdge(from: root, to: c)
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: c, to: d)
        
        return graph
    }
    
    func createComplexTreeGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        
        let root = graph.addVertex { $0.label = "root" }
        let a = graph.addVertex { $0.label = "a" }
        let b = graph.addVertex { $0.label = "b" }
        let c = graph.addVertex { $0.label = "c" }
        let d = graph.addVertex { $0.label = "d" }
        let e = graph.addVertex { $0.label = "e" }
        let f = graph.addVertex { $0.label = "f" }
        let g = graph.addVertex { $0.label = "g" }
        
        graph.addEdge(from: root, to: a)
        graph.addEdge(from: root, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: a, to: d)
        graph.addEdge(from: b, to: d)
        graph.addEdge(from: b, to: e)
        graph.addEdge(from: c, to: f)
        graph.addEdge(from: d, to: f)
        graph.addEdge(from: d, to: g)
        graph.addEdge(from: e, to: g)
        
        return graph
    }

    // MARK: - Core Behavior

    @Test func order() {
        let graph = createMultiLevelTreeGraph()
        
        let root = graph.findVertex(labeled: "root")!
        
        let result = graph.traverse(from: root, using: .bfs())
        #expect(result.vertexLabels(in: graph) == ["root", "a", "b", "c", "x", "y", "z"])
    }
    
    @Test func startsAtSourceAndComputesDistancesAndPaths() {
        let graph = createSimpleTreeGraph()
        
        let root = graph.findVertex(labeled: "root")!
        let a = graph.findVertex(labeled: "a")!
        let b = graph.findVertex(labeled: "b")!
        let c = graph.findVertex(labeled: "c")!
        let d = graph.findVertex(labeled: "d")!

        let result = BreadthFirstSearch(on: graph, from: root)
            .prefix { $0.depth() < 3 }
            .reduce(into: nil) { $0 = $1 }

        #expect(result?.depth(of: root) == 0)
        #expect(result?.depth(of: a) == 1)
        #expect(result?.depth(of: c) == 1)
        #expect(result?.depth(of: b) == 2)
        #expect(result?.depth(of: d) == 2)

        #expect(result?.vertices(to: a, in: graph) == [root, a])
        #expect(result?.vertices(to: b, in: graph) == [root, a, b])
        #expect(result?.vertices(to: c, in: graph) == [root, c])
        #expect(result?.vertices(to: d, in: graph) == [root, c, d])
    }

    @Test func visitorReportsDiscoveryThenExaminationInBFSOrder() {
        let graph = createComplexTreeGraph()
        
        let root = graph.findVertex(labeled: "root")!

        var discovered: [Any] = []
        var examined: [Any] = []

        BreadthFirstSearch(on: graph, from: root)
            .withVisitor {
                .init(
                    discoverVertex: { discovered.append($0) },
                    examineVertex: { examined.append($0) }
                )
            }
            .forEach { _ in }

        #expect(discovered.count == 7)
        #expect(examined.count == 8)
    }

    @Test func traversalWrapperReturnsBFSVertexAndEdgeOrder() {
        let graph = createSimpleTreeGraph()
        
        let root = graph.findVertex(labeled: "root")!
        let a = graph.findVertex(labeled: "a")!
        let b = graph.findVertex(labeled: "b")!
        let c = graph.findVertex(labeled: "c")!
        let d = graph.findVertex(labeled: "d")!
        
        let edges = Array(graph.edges())
        let ra = edges.first { graph.source(of: $0) == root && graph.destination(of: $0) == a }!
        let rc = edges.first { graph.source(of: $0) == root && graph.destination(of: $0) == c }!
        let ab = edges.first { graph.source(of: $0) == a && graph.destination(of: $0) == b }!
        let cd = edges.first { graph.source(of: $0) == c && graph.destination(of: $0) == d }!

        let result = graph.traverse(from: root, using: .bfs())
        #expect(result.vertices == [root, a, c, b, d])
        #expect(result.edges == [ra, rc, ab, cd])
    }

    // MARK: - Multi-Backend Coverage

    @Test func visitsAllReachableVertices_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let isolated = graph.addVertex { $0.label = "X" }
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: c)
            let result = graph.traverse(from: a, using: .bfs())
            #expect(result.vertices.count == 3, "[\(backend)] reachable count")
            #expect(!result.vertices.contains(isolated), "[\(backend)] isolated vertex must not be visited")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    @Test func breadthBeforeDepth_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            let root  = graph.addVertex { $0.label = "root" }
            let l1a   = graph.addVertex { $0.label = "l1a" }
            let l1b   = graph.addVertex { $0.label = "l1b" }
            let l2    = graph.addVertex { $0.label = "l2" }
            graph.addEdge(from: root, to: l1a)
            graph.addEdge(from: root, to: l1b)
            graph.addEdge(from: l1a, to: l2)
            let result = graph.traverse(from: root, using: .bfs())
            let idx = { result.vertices.firstIndex(of: $0)! }
            #expect(idx(l1a) < idx(l2), "[\(backend)] l1a must come before l2")
            #expect(idx(l1b) < idx(l2), "[\(backend)] l1b must come before l2")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    @Test func singleVertex_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            let a = graph.addVertex()
            let result = graph.traverse(from: a, using: .bfs())
            #expect(result.vertices == [a], "[\(backend)] single-vertex graph visits only that vertex")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    // MARK: - Visitor Support

    /// Exercises all six BFS visitor events through a composed visitor pair.
    ///
    /// Graph: a→b, a→c, b→c — b→c triggers `nonTreeEdge` because c is already discovered.
    /// - `discoverVertex` fires for b and c (NOT the source a, which starts pre-discovered).
    /// - `examineVertex` fires for a, b, c (once each when dequeued).
    /// - `examineEdge` fires for a→b, a→c, b→c (all 3 edges).
    /// - `treeEdge` fires for a→b and a→c (both lead to undiscovered vertices).
    /// - `nonTreeEdge` fires for b→c (c is already in the queue/discovered).
    /// - `finishVertex` fires for a, b, c once their neighbors are processed.
    @Test func composedVisitorsReceiveAllEvents() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        // a→b and a→c are tree edges; b→c fires nonTreeEdge (c already discovered via a→c)
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: b, to: c)

        var discovered1 = 0; var discovered2 = 0
        var examined1 = 0;   var examined2 = 0
        var examEdge1 = 0;   var examEdge2 = 0
        var tree1 = 0;       var tree2 = 0
        var nonTree1 = 0;    var nonTree2 = 0
        var finished1 = 0;   var finished2 = 0

        var v1 = BreadthFirstSearch<DefaultAdjacencyList>.Visitor()
        v1.discoverVertex = { _ in discovered1 += 1 }
        v1.examineVertex  = { _ in examined1 += 1 }
        v1.examineEdge    = { _ in examEdge1 += 1 }
        v1.treeEdge       = { _ in tree1 += 1 }
        v1.nonTreeEdge    = { _ in nonTree1 += 1 }
        v1.finishVertex   = { _ in finished1 += 1 }

        var v2 = BreadthFirstSearch<DefaultAdjacencyList>.Visitor()
        v2.discoverVertex = { _ in discovered2 += 1 }
        v2.examineVertex  = { _ in examined2 += 1 }
        v2.examineEdge    = { _ in examEdge2 += 1 }
        v2.treeEdge       = { _ in tree2 += 1 }
        v2.nonTreeEdge    = { _ in nonTree2 += 1 }
        v2.finishVertex   = { _ in finished2 += 1 }

        let combined = v1.combined(with: v2)
        BreadthFirstSearch(on: graph, from: a)
            .withVisitor { combined }
            .forEach { _ in }

        // discoverVertex does NOT fire for source a; fires for b and c
        #expect(discovered1 == 2,  "discoverVertex fires for b and c (not source a)")
        #expect(discovered2 == 2)
        #expect(examined1 == 3,    "examineVertex fires for a, b, c when dequeued")
        #expect(examined2 == 3)
        #expect(examEdge1 == 3,    "examineEdge fires for all 3 edges")
        #expect(examEdge2 == 3)
        #expect(tree1 == 2,        "treeEdge fires for a→b and a→c")
        #expect(tree2 == 2)
        #expect(nonTree1 == 1,     "nonTreeEdge fires for b→c (c already discovered)")
        #expect(nonTree2 == 1)
        #expect(finished1 == 3,    "finishVertex fires for a, b, c")
        #expect(finished2 == 3)
        // Both composed visitors must see identical event counts
        #expect(discovered1 == discovered2)
        #expect(examined1 == examined2)
        #expect(examEdge1 == examEdge2)
        #expect(tree1 == tree2)
        #expect(nonTree1 == nonTree2)
        #expect(finished1 == finished2)
    }

    // MARK: - Result Context API Coverage

    /// `predecessor(in:)`, `predecessorEdge()`, `vertices(in:)`, `edges(in:)` and `path(in:)` are
    /// currentVertex-based convenience wrappers on `BFSResult`. They can only be called on
    /// non-source elements (source has no predecessor), so we skip the first element.
    @Test func bfsResultContextMethodsDuringIteration() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)

        var pathLengths: [Int] = []
        var edgeLengths: [Int] = []
        var pathSteps: [Int] = []
        for result in BreadthFirstSearch(on: graph, from: a) {
            pathLengths.append(result.vertices(in: graph).count)
            edgeLengths.append(result.edges(in: graph).count)
            pathSteps.append(result.path(in: graph).count)
            if result.currentVertex != a {
                // Safe to call on non-source vertices that have a predecessor
                _ = result.predecessor(in: graph)
                _ = result.predecessorEdge()
            }
        }

        // a: path=[a] (1 vertex, 0 edges); b: path=[a,b] (2 vertices, 1 edge); c: path=[a,b,c] (3 vertices, 2 edges)
        #expect(pathLengths == [1, 2, 3], "path vertex counts grow along the chain")
        #expect(edgeLengths == [0, 1, 2], "path edge counts grow along the chain")
        #expect(pathSteps  == [0, 1, 2], "path(in:) step counts grow along the chain")
    }

    /// `hasPath(to:)` returns true for reachable vertices and false for unreachable ones.
    /// `predecessor(of:in:)` returns the tree predecessor vertex or nil for the source.
    @Test func bfsResultHasPathAndPredecessorForExplicitVertices() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let isolated = graph.addVertex { $0.label = "X" }
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)

        let result = BreadthFirstSearch(on: graph, from: a).reduce(into: nil) { $0 = $1 }
        #expect(result?.hasPath(to: a) == true,  "source is always reachable")
        #expect(result?.hasPath(to: b) == true,  "b reachable via a→b")
        #expect(result?.hasPath(to: c) == true,  "c reachable via a→b→c")
        #expect(result?.hasPath(to: isolated) == false, "isolated vertex is not reachable from source")

        #expect(result?.predecessor(of: a, in: graph) == nil, "source has no predecessor")
        #expect(result?.predecessor(of: b, in: graph) == a,   "b's predecessor is a")
        #expect(result?.predecessor(of: c, in: graph) == b,   "c's predecessor is b")
    }

    // MARK: - Edge Cases

    /// A self-loop (a → a) must not cause BFS to visit `a` more than once.
    ///
    /// The gray/black coloring used by BFS prevents revisiting already-discovered vertices,
    /// so `a` is colored gray on first discovery and the self-loop is ignored on examination.
    @Test func selfLoopDoesNotCauseInfiniteVisits() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: a)  // self-loop
        graph.addEdge(from: a, to: b)

        let result = graph.traverse(from: a, using: .bfs())
        #expect(result.vertices.count == 2, "BFS must visit exactly 2 vertices (a and b), not loop on the self-edge")
        #expect(result.vertices.first == a)
        #expect(Set(result.vertices) == Set([a, b]))
    }

    /// Two parallel edges a → b must not cause BFS to visit `b` twice.
    ///
    /// Once `b` is discovered via the first edge, it is colored gray. The second edge to `b`
    /// is examined but `b` is already discovered, so it is not enqueued again.
    @Test func parallelEdgesVisitDestinationOnce() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: b)  // duplicate edge
        graph.addEdge(from: a, to: c)

        let result = graph.traverse(from: a, using: .bfs())
        #expect(result.vertices.count == 3, "BFS must visit each vertex exactly once despite parallel edges")
        #expect(Set(result.vertices) == Set([a, b, c]))
    }
}


