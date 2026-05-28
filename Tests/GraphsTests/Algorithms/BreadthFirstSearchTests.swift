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


