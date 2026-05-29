@testable import Graphs
import Testing

struct DepthLimitedSearchTests {
    @Test func depthLimitedDFS_PrunesBeyondLimit() {
        var graph = AdjacencyList()
        let root = graph.addVertex()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let x = graph.addVertex()
        let y = graph.addVertex()

        let ra = graph.addEdge(from: root, to: a)!
        let rb = graph.addEdge(from: root, to: b)!
        graph.addEdge(from: a, to: x)
        graph.addEdge(from: b, to: y)

        let result = graph.traverse(from: root, using: .depthLimitedDFS(maxDepth: 1))

        // Only root and its immediate children should be discovered; deeper nodes pruned
        #expect(result.vertices == [root, a, b])
        #expect(result.edges == [ra, rb])
    }

    @Test func depthLimitedDFS_WithZeroLimit_VisitsOnlySource() {
        var graph = AdjacencyList()
        let root = graph.addVertex()
        let a = graph.addVertex()
        let b = graph.addVertex()
        graph.addEdge(from: root, to: a)
        graph.addEdge(from: root, to: b)

        let result = graph.traverse(from: root, using: .depthLimitedDFS(maxDepth: 0))

        #expect(result.vertices == [root])
        #expect(result.edges.isEmpty)
    }

    @Test func depthLimitedDFS_LargeLimit_VisitsAllReachable() {
        var graph = AdjacencyList()
        let root = graph.addVertex()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        graph.addEdge(from: root, to: a)
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)

        // Limit larger than graph depth should visit everything reachable
        let result = graph.traverse(from: root, using: .depthLimitedDFS(maxDepth: 100))

        #expect(result.vertices.count == 4, "Large depth limit should visit all reachable vertices")
        #expect(Set(result.vertices) == Set([root, a, b, c]))
    }

    @Test func depthLimitedDFS_SelfLoop_DoesNotInfiniteLoop() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        graph.addEdge(from: a, to: a)  // self-loop
        graph.addEdge(from: a, to: b)

        let result = graph.traverse(from: a, using: .depthLimitedDFS(maxDepth: 5))

        #expect(result.vertices.count == 2, "Self-loop must not cause infinite traversal")
        #expect(Set(result.vertices) == Set([a, b]))
    }

    // MARK: - Multi-Backend Coverage

    @Test func prunesBeyondLimit_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            let root  = graph.addVertex { $0.label = "root" }
            let l1    = graph.addVertex { $0.label = "l1" }
            let l2    = graph.addVertex { $0.label = "l2" }
            let l3    = graph.addVertex { $0.label = "l3" }
            graph.addEdge(from: root, to: l1)
            graph.addEdge(from: l1, to: l2)
            graph.addEdge(from: l2, to: l3)

            let result = graph.traverse(from: root, using: .depthLimitedDFS(maxDepth: 2))
            #expect(result.vertices.count == 3, "[\(backend)] depth-2 limit visits root, l1, l2 but not l3")
            #expect(!result.vertices.contains(l3), "[\(backend)] l3 at depth 3 must be pruned")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    // MARK: - Visitor Support

    /// `DepthLimitedDFSTraversal` delegates to DFS internally and forwards its visitor.
    /// Two composed visitors must each receive `discoverVertex` for every vertex reached
    /// within the depth limit and `treeEdge` for every tree edge traversed.
    @Test func composedVisitorsReceiveAllEvents() {
        var graph = AdjacencyList()
        let root = graph.addVertex { $0.label = "root" }
        let a = graph.addVertex { $0.label = "a" }
        let b = graph.addVertex { $0.label = "b" }
        graph.addEdge(from: root, to: a)
        graph.addEdge(from: a, to: b)

        var discovered1 = 0; var discovered2 = 0
        var treeEdges1 = 0;  var treeEdges2 = 0

        var v1 = DepthLimitedDFSTraversal<DefaultAdjacencyList>.Visitor()
        v1.discoverVertex = { _ in discovered1 += 1 }
        v1.treeEdge       = { _ in treeEdges1 += 1 }

        var v2 = DepthLimitedDFSTraversal<DefaultAdjacencyList>.Visitor()
        v2.discoverVertex = { _ in discovered2 += 1 }
        v2.treeEdge       = { _ in treeEdges2 += 1 }

        let combined = v1.combined(with: v2)
        _ = DepthLimitedDFSTraversal<DefaultAdjacencyList>(maxDepth: 10)
            .traverse(from: root, in: graph, visitor: combined)

        #expect(discovered1 == 3, "all 3 vertices in chain root→a→b must be discovered")
        #expect(discovered2 == 3)
        #expect(treeEdges1 == 2, "chain root→a→b has exactly 2 tree edges")
        #expect(treeEdges2 == 2)
        #expect(discovered1 == discovered2, "both composed visitors must receive identical discoverVertex events")
        #expect(treeEdges1 == treeEdges2, "both composed visitors must receive identical treeEdge events")
    }
}


