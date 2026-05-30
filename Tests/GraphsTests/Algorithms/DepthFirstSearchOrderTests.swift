import Testing

@testable import Graphs

struct DFSOrderTests {

    @Test func preorderVisitsParentBeforeChildren() {
        var graph = AdjacencyList()

        // Tree structure:
        //     a
        //    / \
        //   b   c
        //  /
        // d
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()

        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: b, to: d)

        let result = Array(graph.search(from: a, using: .dfs(order: .preorder)))
        #expect(result == [a, b, d, c])
    }

    @Test func postorderVisitsChildrenBeforeParent() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()

        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: b, to: d)

        let result = Array(graph.search(from: a, using: .dfs(order: .postorder)))
        #expect(result == [d, b, c, a])
    }

    @Test func lazyEvaluationStopsEarly() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()

        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: b, to: d)

        let result = graph.search(from: a, using: .dfs(order: .preorder)).prefix(2)

        let collected = Array(result)
        #expect(collected == [a, b])
    }

    // MARK: - Multi-Backend Coverage

    @Test func preorderRootBeforeDescendants_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where
            G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
            G.VertexDescriptor: Hashable
        {
            let a = graph.addVertex { $0.label = "a" }
            let b = graph.addVertex { $0.label = "b" }
            let c = graph.addVertex { $0.label = "c" }
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: a, to: c)

            let labels = graph.search(from: a, using: .dfs(order: .preorder)).map { graph[$0].label }
            let order = Array(labels)
            #expect(order.count == 3, "[\(backend)] all 3 vertices visited")
            #expect(order.first == "a", "[\(backend)] root 'a' must come first in preorder")
            let aIdx = order.firstIndex(of: "a")!
            let bIdx = order.firstIndex(of: "b")!
            let cIdx = order.firstIndex(of: "c")!
            #expect(aIdx < bIdx, "[\(backend)] parent 'a' before child 'b' in preorder")
            #expect(aIdx < cIdx, "[\(backend)] parent 'a' before child 'c' in preorder")
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

    @Test func postorderRootAfterDescendants_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where
            G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
            G.VertexDescriptor: Hashable
        {
            let a = graph.addVertex { $0.label = "a" }
            let b = graph.addVertex { $0.label = "b" }
            let c = graph.addVertex { $0.label = "c" }
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: a, to: c)

            let labels = graph.search(from: a, using: .dfs(order: .postorder)).map { graph[$0].label }
            let order = Array(labels)
            #expect(order.count == 3, "[\(backend)] all 3 vertices visited")
            #expect(order.last == "a", "[\(backend)] root 'a' must come last in postorder")
            let aIdx = order.firstIndex(of: "a")!
            let bIdx = order.firstIndex(of: "b")!
            let cIdx = order.firstIndex(of: "c")!
            #expect(bIdx < aIdx, "[\(backend)] child 'b' before parent 'a' in postorder")
            #expect(cIdx < aIdx, "[\(backend)] child 'c' before parent 'a' in postorder")
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

    #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        @Test func inorderVisitsLeftSubtreeThenRootThenRightSubtree() {
            var graph = AdjacencyList(edgeStore: BinaryEdgeStore())

            // Binary tree structure:
            //       a
            //     /   \
            //    b     c
            //   / \
            //  d   e
            let a = graph.addVertex()
            let b = graph.addVertex()
            let c = graph.addVertex()
            let d = graph.addVertex()
            let e = graph.addVertex()

            graph.setLeftNeighbor(of: a, to: b)
            graph.setRightNeighbor(of: a, to: c)
            graph.setLeftNeighbor(of: b, to: d)
            graph.setRightNeighbor(of: b, to: e)

            let result = Array(graph.search(from: a, using: .dfs(order: .inorder)))
            #expect(result == [d, b, e, a, c])
        }
    #endif
}
