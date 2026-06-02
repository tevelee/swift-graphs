import Testing

@testable import Graphs

struct DepthFirstSearchTests {

    // MARK: - Test Graphs

    func createTreeGraph() -> some AdjacencyListProtocol {
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

    func createCyclicGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()

        let a = graph.addVertex { $0.label = "a" }
        let b = graph.addVertex { $0.label = "b" }
        let c = graph.addVertex { $0.label = "c" }

        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: a)

        return graph
    }

    // MARK: - Core Behavior

    @Test func reconstructsPathsFromPredecessorEdges() {
        let graph = createTreeGraph()

        let root = graph.findVertex(labeled: "root")!
        let a = graph.findVertex(labeled: "a")!
        let b = graph.findVertex(labeled: "b")!
        let c = graph.findVertex(labeled: "c")!
        let d = graph.findVertex(labeled: "d")!

        let last = DepthFirstSearch(on: graph, from: root).reduce(into: nil) { $0 = $1 }
        #expect(last?.vertices(to: a, in: graph) == [root, a])
        #expect(last?.vertices(to: b, in: graph) == [root, a, b])
        #expect(last?.vertices(to: c, in: graph) == [root, c])
        #expect(last?.vertices(to: d, in: graph) == [root, c, d])
    }

    @Test func visitorSeesPreorderOfVertices() {
        let graph = createComplexTreeGraph()

        let root = graph.findVertex(labeled: "root")!

        var discovered: [Any] = []
        var examined: [Any] = []
        DepthFirstSearch(on: graph, from: root)
            .withVisitor {
                .init(
                    discoverVertex: { discovered.append($0) },
                    examineVertex: { examined.append($0) }
                )
            }
            .forEach { _ in }
        #expect(discovered.count == 8)
        #expect(examined.count == 8)
    }

    @Test func traversalWrapperReturnsVerticesPreorderAndEdgesInAdjacencyOrder() {
        let graph = createTreeGraph()

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

        let result = graph.traverse(from: root, using: .dfs())
        #expect(result.vertices == [root, a, b, c, d])
        #expect(result.edges == [ra, rc, ab, cd])
    }

    @Test func traversalWrapperReturnsVerticesPostorderAndEdgesInAdjacencyOrder() {
        let graph = createTreeGraph()

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

        let result = graph.traverse(from: root, using: .dfs(order: .postorder))
        #expect(result.vertices == [b, a, d, c, root])
        #expect(result.edges == [ra, rc, ab, cd])
    }

    @Test func classificationDetectsBackEdgesInCycles() {
        let graph = createCyclicGraph()

        let a = graph.findVertex(labeled: "a")!

        var backEdges: [Any] = []
        var treeEdges: [Any] = []
        DepthFirstSearch(on: graph, from: a)
            .withVisitor {
                .init(
                    treeEdge: { treeEdges.append($0) },
                    backEdge: { backEdges.append($0) }
                )
            }
            .forEach { _ in }

        #expect(backEdges.count == 1)
        #expect(treeEdges.count == 2)
    }

    // MARK: - Multi-Backend Coverage

    @Test func visitsAllReachableVertices_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where
            G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
            G.VertexDescriptor: Hashable
        {
            let a = graph.addVertex { $0.label = "a" }
            let b = graph.addVertex { $0.label = "b" }
            let c = graph.addVertex { $0.label = "c" }
            let isolated = graph.addVertex { $0.label = "x" }
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: c)
            let result = graph.traverse(from: a, using: .dfs())
            #expect(result.vertices.count == 3, "[\(backend)] reachable count")
            #expect(!result.vertices.contains(isolated), "[\(backend)] isolated vertex must not appear")
        }
        var g1 = AdjacencyList()
        check(&g1, "default")
        var g4 = AdjacencyMatrix()
        check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
            var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges())
            check(&g2, "CSR")
            var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges())
            check(&g3, "COO")
        #endif
    }

    @Test func preorderBeforeChildren_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where
            G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
            G.VertexDescriptor: Hashable
        {
            let root = graph.addVertex { $0.label = "root" }
            let child = graph.addVertex { $0.label = "child" }
            let leaf = graph.addVertex { $0.label = "leaf" }
            graph.addEdge(from: root, to: child)
            graph.addEdge(from: child, to: leaf)
            let result = graph.traverse(from: root, using: .dfs())
            let idx = { result.vertices.firstIndex(of: $0)! }
            #expect(idx(root) < idx(child), "[\(backend)] root before child in preorder")
            #expect(idx(child) < idx(leaf), "[\(backend)] child before leaf in preorder")
        }
        var g1 = AdjacencyList()
        check(&g1, "default")
        var g4 = AdjacencyMatrix()
        check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
            var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges())
            check(&g2, "CSR")
            var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges())
            check(&g3, "COO")
        #endif
    }

    @Test func singleVertex_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where
            G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
            G.VertexDescriptor: Hashable
        {
            let a = graph.addVertex()
            let result = graph.traverse(from: a, using: .dfs())
            #expect(result.vertices == [a], "[\(backend)]")
        }
        var g1 = AdjacencyList()
        check(&g1, "default")
        var g4 = AdjacencyMatrix()
        check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
            var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges())
            check(&g2, "CSR")
            var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges())
            check(&g3, "COO")
        #endif
    }

    // MARK: - Visitor Support

    /// Exercises all DFS visitor events through a composed visitor pair.
    ///
    /// Graph: a→b, b→c, b→a, a→c, a→d, d→c — covers all reachable edge classifications.
    ///
    /// The iterative DFS classifies edges when a vertex is first popped. At that moment
    /// all WHITE neighbors are pushed simultaneously and receive `treeEdge` (including a→c
    /// and b→c, even though they share a destination). Later, once c is BLACK, d→c fires
    /// `crossEdge` (d.discTime > c.discTime).
    ///
    /// Note: `forwardEdge` cannot fire in this iterative implementation — the classification
    /// criterion (sourceDiscTime < destDiscTime ∧ dest.color=BLACK) is structurally unreachable
    /// from a single source when all neighbors are pushed in one batch on first-visit.
    ///
    /// - `discoverVertex` / `examineVertex` / `finishVertex`: once per vertex (4 vertices).
    /// - `examineEdge`: once per directed edge (6 edges).
    /// - `treeEdge`: fires for all edges to WHITE destinations (a→b, a→c, a→d, b→c = 4).
    /// - `backEdge`: fires for b→a (a is GRAY/on the DFS stack when b examines b→a).
    /// - `crossEdge`: fires for d→c (c is BLACK; d.discTime > c.discTime).
    @Test func composedVisitorsReceiveAllEvents() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        graph.addEdge(from: a, to: b)  // tree edge
        graph.addEdge(from: b, to: c)  // tree edge (c is WHITE when b processes it)
        graph.addEdge(from: b, to: a)  // back edge (a is GRAY when b processes it)
        graph.addEdge(from: a, to: c)  // tree edge (c is still WHITE when a processes all edges)
        graph.addEdge(from: a, to: d)  // tree edge
        graph.addEdge(from: d, to: c)  // cross edge (c is BLACK; d.discTime > c.discTime)

        var discovered1 = 0
        var discovered2 = 0
        var examined1 = 0
        var examined2 = 0
        var examEdge1 = 0
        var examEdge2 = 0
        var tree1 = 0
        var tree2 = 0
        var back1 = 0
        var back2 = 0
        var forward1 = 0
        var forward2 = 0
        var cross1 = 0
        var cross2 = 0
        var finished1 = 0
        var finished2 = 0

        var v1 = DepthFirstSearch<DefaultAdjacencyList>.Visitor()
        v1.discoverVertex = { _ in discovered1 += 1 }
        v1.examineVertex = { _ in examined1 += 1 }
        v1.examineEdge = { _ in examEdge1 += 1 }
        v1.treeEdge = { _ in tree1 += 1 }
        v1.backEdge = { _ in back1 += 1 }
        v1.forwardEdge = { _ in forward1 += 1 }
        v1.crossEdge = { _ in cross1 += 1 }
        v1.finishVertex = { _ in finished1 += 1 }

        var v2 = DepthFirstSearch<DefaultAdjacencyList>.Visitor()
        v2.discoverVertex = { _ in discovered2 += 1 }
        v2.examineVertex = { _ in examined2 += 1 }
        v2.examineEdge = { _ in examEdge2 += 1 }
        v2.treeEdge = { _ in tree2 += 1 }
        v2.backEdge = { _ in back2 += 1 }
        v2.forwardEdge = { _ in forward2 += 1 }
        v2.crossEdge = { _ in cross2 += 1 }
        v2.finishVertex = { _ in finished2 += 1 }

        let combined = v1.combined(with: v2)
        DepthFirstSearch(on: graph, from: a)
            .withVisitor { combined }
            .forEach { _ in }

        #expect(discovered1 == 4, "discoverVertex fires for a, b, c, d")
        #expect(discovered2 == 4)
        #expect(examined1 == 4, "examineVertex fires for each vertex when processing its edges")
        #expect(examined2 == 4)
        #expect(examEdge1 == 6, "examineEdge fires for all 6 edges")
        #expect(examEdge2 == 6)
        // a→b, a→c, a→d are all WHITE when a processes them; b→c is WHITE when b processes it → 4 tree edges
        #expect(tree1 == 4, "treeEdge fires for all edges to WHITE destinations (a→b, a→c, a→d, b→c)")
        #expect(tree2 == 4)
        #expect(back1 >= 1, "backEdge fires for b→a (a is GRAY/on the DFS stack)")
        #expect(back2 >= 1)
        // forwardEdge is structurally unreachable in the single-source iterative DFS
        #expect(forward1 == 0, "forwardEdge cannot fire in this iterative DFS (by design)")
        #expect(forward2 == 0)
        #expect(cross1 >= 1, "crossEdge fires for d→c (c is BLACK; d.discTime > c.discTime)")
        #expect(cross2 >= 1)
        #expect(finished1 == 4, "finishVertex fires for all 4 vertices")
        #expect(finished2 == 4)
        // Both composed visitors must see identical event counts
        #expect(discovered1 == discovered2)
        #expect(examined1 == examined2)
        #expect(examEdge1 == examEdge2)
        #expect(tree1 == tree2)
        #expect(back1 == back2)
        #expect(forward1 == forward2)
        #expect(cross1 == cross2)
        #expect(finished1 == finished2)
    }

    // MARK: - Result Context API Coverage

    /// `discoveryTime(of:)` and `finishTime(of:)` return the DFS timestamps stored in the
    /// result property map. For the chain a→b→c: a is discovered first and finished last,
    /// c is discovered last and finished first — the classic bracket property of DFS.
    @Test func dfsResultRecordsDiscoveryAndFinishTimes() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)

        let result = DepthFirstSearch(on: graph, from: a).reduce(into: nil) { $0 = $1 }
        guard let r = result else {
            Issue.record("DFS result must not be nil")
            return
        }

        let da = r.discoveryTime(of: a)
        let db = r.discoveryTime(of: b)
        let dc = r.discoveryTime(of: c)
        let fa = r.finishTime(of: a)
        let fb = r.finishTime(of: b)
        let fc = r.finishTime(of: c)

        // Discovery order: a → b → c (deepening)
        #expect(da < db, "a must be discovered before b")
        #expect(db < dc, "b must be discovered before c")

        // Finish order: c → b → a (backtracking)
        #expect(fc < fb, "c must finish before b")
        #expect(fb < fa, "b must finish before a")
    }

    /// `predecessor(of:in:)` and `edges(to:in:)` allow explicit path reconstruction on
    /// the DFS result, independent of whichever vertex is currently active.
    @Test func dfsResultProvidesExplicitVertexPathReconstruction() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)

        let result = DepthFirstSearch(on: graph, from: a).reduce(into: nil) { $0 = $1 }
        guard let r = result else {
            Issue.record("DFS result must not be nil")
            return
        }

        #expect(r.predecessor(of: a, in: graph) == nil, "source has no predecessor")
        #expect(r.predecessor(of: b, in: graph) == a, "b's predecessor is a")
        #expect(r.predecessor(of: c, in: graph) == b, "c's predecessor is b")
        #expect(r.edges(to: c, in: graph).count == 2, "path a→b→c uses 2 edges")
        #expect(r.edges(to: a, in: graph).isEmpty, "path to source uses 0 edges")
    }

    /// `depth()` on the DFS result returns the depth of `currentVertex` (using finish order).
    /// The DFS iterator yields results when vertices FINISH (postorder), so the deepest leaf
    /// finishes first (depth 2) and the source finishes last (depth 0).
    @Test func dfsResultDepthIsAccessibleDuringIteration() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)

        var depths: [UInt] = []
        DepthFirstSearch(on: graph, from: a).forEach { result in
            depths.append(result.depth())
        }

        // DFS yields in postorder: c finishes first (depth 2), then b (1), then a (0)
        #expect(depths.first == 2, "deepest leaf (first to finish) has depth 2")
        #expect(depths.last == 0, "source vertex (last to finish) has depth 0")
        #expect(depths.max() == 2, "chain a→b→c has maximum depth 2")
        #expect(depths.count == 3, "three distinct vertices have their depths recorded")
    }

    /// `DFSTime` is `Comparable` and `ExpressibleByIntegerLiteral`.
    /// Integer literals produce `.discovered(n)` and the comparison order is:
    /// `.undiscovered` < `.discovered` < `.finished`.
    @Test func dfsTimeComparableAndIntegerLiteral() {
        let undiscovered = DepthFirstSearch<DefaultAdjacencyList>.Time.undiscovered
        let discovered2 = DepthFirstSearch<DefaultAdjacencyList>.Time.discovered(2)
        let finished3 = DepthFirstSearch<DefaultAdjacencyList>.Time.finished(3)
        let fromLiteral: DepthFirstSearch<DefaultAdjacencyList>.Time = 5  // integerLiteral init

        // Ordering
        #expect(undiscovered < discovered2, "undiscovered < discovered(2)")
        #expect(undiscovered < finished3, "undiscovered < finished(3)")
        #expect(discovered2 < finished3, "discovered(2) < finished(3)")
        #expect(!(finished3 < undiscovered), "finished(3) is NOT < undiscovered")
        #expect(!(discovered2 < undiscovered), "discovered(2) is NOT < undiscovered")

        // Integer literal creates a .discovered time
        if case .discovered(let v) = fromLiteral {
            #expect(v == 5, "integerLiteral 5 produces .discovered(5)")
        } else {
            Issue.record("integerLiteral should produce .discovered time")
        }
    }

    // MARK: - Edge Cases

    /// A self-loop (a → a) must be classified as a back edge, not a tree edge,
    /// and must not cause DFS to visit `a` more than once.
    ///
    /// DFS colors vertices gray on first discovery. When examining `a`'s outgoing edges,
    /// the self-loop points back to a gray vertex — so it fires the `backEdge` hook and
    /// is skipped, preventing an infinite recursion.
    @Test func selfLoopIsBackEdgeAndDoesNotRevisitVertex() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: a)  // self-loop
        graph.addEdge(from: a, to: b)

        var backEdges: [Any] = []
        var treeEdges: [Any] = []
        DepthFirstSearch(on: graph, from: a)
            .withVisitor {
                .init(
                    treeEdge: { treeEdges.append($0) },
                    backEdge: { backEdges.append($0) }
                )
            }
            .forEach { _ in }

        let result = graph.traverse(from: a, using: .dfs())
        #expect(result.vertices.count == 2, "DFS must visit exactly 2 vertices (a and b), not revisit a via self-loop")
        #expect(backEdges.count >= 1, "The self-loop a→a must be classified as a back edge")
        #expect(treeEdges.count == 1, "Only the tree edge a→b should be a tree edge")
    }

    /// Two parallel edges a → b must not cause DFS to visit `b` more than once.
    ///
    /// Once `b` is colored gray (discovered), the second parallel edge from `a` to `b`
    /// is observed as a forward/cross edge and `b` is not pushed onto the DFS stack again.
    @Test func parallelEdgesVisitDestinationOnce() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: b)  // duplicate edge
        graph.addEdge(from: a, to: c)

        let result = graph.traverse(from: a, using: .dfs())
        #expect(result.vertices.count == 3, "DFS must visit each vertex exactly once despite parallel edges")
        #expect(Set(result.vertices) == Set([a, b, c]))
    }

    /// Parallel edges a → b (two edges) must fire `treeEdge` exactly once for `b`.
    ///
    /// The iterative DFS batches all white-neighbor classification in one pass. Without
    /// deduplication, both parallel edges would see `b` as white and both would fire
    /// `treeEdge`. Only the first edge to each unique white destination is a tree edge.
    @Test func parallelEdgesFireTreeEdgeOncePerDestination() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: b)  // parallel edge to same destination

        var treeEdgeCount = 0
        var examineEdgeCount = 0
        DepthFirstSearch(on: graph, from: a)
            .withVisitor {
                .init(
                    examineEdge: { _ in examineEdgeCount += 1 },
                    treeEdge: { _ in treeEdgeCount += 1 }
                )
            }
            .forEach { _ in }

        #expect(examineEdgeCount == 2, "examineEdge fires for every edge including parallel ones")
        #expect(treeEdgeCount == 1, "treeEdge fires only once for b despite two parallel edges")
    }

    /// When `shouldTraverse` vetoes the first parallel edge to a white vertex, the second
    /// parallel edge must still be presented to `shouldTraverse` and, if accepted, must
    /// result in the destination being visited.
    ///
    /// Regression test for the ordering bug where `pendingWhite.insert` ran before the
    /// veto check, permanently blocking all parallel edges once any one was rejected.
    @Test func shouldTraverseVetoOnFirstParallelEdgeAllowsSecondParallelEdge() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: b)  // parallel edge

        // Reject the first shouldTraverse call (first parallel edge), accept the second.
        var vetoCallCount = 0
        var bDiscovered = false
        var treeEdgeCount = 0
        DepthFirstSearch(on: graph, from: a)
            .withVisitor {
                .init(
                    discoverVertex: { v in if v == b { bDiscovered = true } },
                    treeEdge: { _ in treeEdgeCount += 1 },
                    shouldTraverse: { _ in
                        vetoCallCount += 1
                        return vetoCallCount > 1
                    }
                )
            }
            .forEach { _ in }

        #expect(bDiscovered, "b must be visited via the second parallel edge despite e1 being vetoed")
        #expect(treeEdgeCount == 1, "treeEdge fires once via the accepted second parallel edge")
    }
}
