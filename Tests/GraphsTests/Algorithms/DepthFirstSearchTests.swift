@testable import Graphs
import Testing

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
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
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
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    @Test func preorderBeforeChildren_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
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
            let result = graph.traverse(from: a, using: .dfs())
            #expect(result.vertices == [a], "[\(backend)]")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
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
}


