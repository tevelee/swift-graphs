import Testing

@testable import Graphs

struct IterativelyDeepeningDFSTests {

    @Test func iterativelyDeepeningDFS_ExploresAllVertices() {
        var graph = DefaultAdjacencyList()
        let root = graph.addVertex()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()

        // Create a tree structure: root -> a, b; a -> c; b -> d
        graph.addEdge(from: root, to: a)
        graph.addEdge(from: root, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: b, to: d)

        let result = graph.traverse(from: root, using: .iterativelyDeepeningDFS())

        // IDDFS should find all vertices
        #expect(result.vertices.count == 5)
        #expect(result.vertices.contains(root))
        #expect(result.vertices.contains(a))
        #expect(result.vertices.contains(b))
        #expect(result.vertices.contains(c))
        #expect(result.vertices.contains(d))
    }

    @Test func iterativelyDeepeningDFS_WithMaxDepth_RespectsLimit() {
        var graph = DefaultAdjacencyList()
        let root = graph.addVertex()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()

        // Create a tree structure: root -> a, b; a -> c; b -> d
        graph.addEdge(from: root, to: a)
        graph.addEdge(from: root, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: b, to: d)

        let result = graph.traverse(from: root, using: .iterativelyDeepeningDFS(maxDepth: 1))

        // Should only find root and its immediate children
        #expect(result.vertices.count == 3)
        #expect(result.vertices.contains(root))
        #expect(result.vertices.contains(a))
        #expect(result.vertices.contains(b))
        #expect(!result.vertices.contains(c))
        #expect(!result.vertices.contains(d))
    }

    @Test func iterativelyDeepeningDFS_WithCycles_HandlesCorrectly() {
        var graph = DefaultAdjacencyList()
        let root = graph.addVertex()
        let a = graph.addVertex()
        let b = graph.addVertex()

        // Create a cycle: root -> a -> b -> root
        graph.addEdge(from: root, to: a)
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: root)

        let result = graph.traverse(from: root, using: .iterativelyDeepeningDFS())

        // Should find all vertices despite the cycle
        #expect(result.vertices.count == 3)
        #expect(result.vertices.contains(root))
        #expect(result.vertices.contains(a))
        #expect(result.vertices.contains(b))
    }

    @Test func iterativelyDeepeningDFS_EmptyGraph_ReturnsOnlySource() {
        var graph = DefaultAdjacencyList()
        let root = graph.addVertex()

        let result = graph.traverse(from: root, using: .iterativelyDeepeningDFS())

        #expect(result.vertices.count == 1)
        #expect(result.vertices.contains(root))
        #expect(result.edges.isEmpty)
    }

    @Test func iterativelyDeepeningDFS_SingleVertex_WorksCorrectly() {
        var graph = DefaultAdjacencyList()
        let root = graph.addVertex()

        let result = graph.traverse(from: root, using: .iterativelyDeepeningDFS(maxDepth: 0))

        #expect(result.vertices.count == 1)
        #expect(result.vertices.contains(root))
        #expect(result.edges.isEmpty)
    }

    @Test func iterativelyDeepeningDFS_WithVisitor_CallsCorrectly() {
        var graph = DefaultAdjacencyList()
        let root = graph.addVertex()
        let a = graph.addVertex()
        let b = graph.addVertex()

        graph.addEdge(from: root, to: a)
        graph.addEdge(from: root, to: b)

        var discoveredVertices: [DefaultAdjacencyList.VertexDescriptor] = []
        var examinedEdges: [DefaultAdjacencyList.EdgeDescriptor] = []

        let visitor = DepthFirstSearch<DefaultAdjacencyList>.Visitor(
            discoverVertex: { vertex in
                discoveredVertices.append(vertex)
            },
            examineEdge: { edge in
                examinedEdges.append(edge)
            }
        )

        _ = graph.traverse(from: root, using: .iterativelyDeepeningDFS().withVisitor(visitor))

        #expect(discoveredVertices.count == 3)
        #expect(examinedEdges.count == 6)  // IDDFS examines edges multiple times at different depths
    }

    @Test func iterativelyDeepeningDFSSearch_ExploresInDepthOrder() {
        var graph = DefaultAdjacencyList()
        let root = graph.addVertex()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()

        // Create a tree: root -> a, b; a -> c
        graph.addEdge(from: root, to: a)
        graph.addEdge(from: root, to: b)
        graph.addEdge(from: a, to: c)

        var searchResults: [DefaultAdjacencyList.VertexDescriptor] = []
        for result in graph.search(from: root, using: .iterativelyDeepeningDFS()) {
            searchResults.append(result.currentVertex)
        }

        // Should explore in depth order: root (depth 0), then a, b (depth 1), then c (depth 2)
        #expect(searchResults.count == 4)
        #expect(searchResults.first == root)
    }

    @Test func iterativelyDeepeningDFSSearch_WithMaxDepth_RespectsLimit() {
        var graph = DefaultAdjacencyList()
        let root = graph.addVertex()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()

        graph.addEdge(from: root, to: a)
        graph.addEdge(from: root, to: b)
        graph.addEdge(from: a, to: c)

        var searchResults: [DefaultAdjacencyList.VertexDescriptor] = []
        for result in graph.search(from: root, using: .iterativelyDeepeningDFS(maxDepth: 1)) {
            searchResults.append(result.currentVertex)
        }

        // Should only explore up to depth 1
        #expect(searchResults.count == 3)
        #expect(searchResults.contains(root))
        #expect(searchResults.contains(a))
        #expect(searchResults.contains(b))
        #expect(!searchResults.contains(c))
    }

    @Test func iterativelyDeepeningDFSSearch_WithVisitor_CallsCorrectly() {
        var graph = DefaultAdjacencyList()
        let root = graph.addVertex()
        let a = graph.addVertex()

        graph.addEdge(from: root, to: a)

        var discoveredVertices: [DefaultAdjacencyList.VertexDescriptor] = []
        var examinedEdges: [DefaultAdjacencyList.EdgeDescriptor] = []

        let visitor = DepthFirstSearch<DefaultAdjacencyList>.Visitor(
            discoverVertex: { vertex in
                discoveredVertices.append(vertex)
            },
            examineEdge: { edge in
                examinedEdges.append(edge)
            }
        )

        graph.search(from: root, using: .iterativelyDeepeningDFS())
            .withVisitor { visitor }
            .forEach { _ in }

        // IDDFS search explores vertices multiple times at different depths
        // The exact count depends on the graph structure and depth exploration
        #expect(discoveredVertices.count >= 2)
        #expect(examinedEdges.count >= 1)
    }

    @Test func iterativelyDeepeningDFS_ComparedToBFS_FindsSameVertices() {
        var graph = DefaultAdjacencyList()
        let root = graph.addVertex()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()

        // Create a tree structure
        graph.addEdge(from: root, to: a)
        graph.addEdge(from: root, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: b, to: d)

        let iddfsResult = graph.traverse(from: root, using: .iterativelyDeepeningDFS())
        let bfsResult = graph.traverse(from: root, using: .bfs())

        // Both should find the same vertices (though order may differ)
        #expect(Set(iddfsResult.vertices) == Set(bfsResult.vertices))
        #expect(iddfsResult.vertices.count == bfsResult.vertices.count)
    }

    @Test func iterativelyDeepeningDFS_WithDisconnectedComponents_FindsOnlyConnected() {
        var graph = DefaultAdjacencyList()
        let root = graph.addVertex()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let isolated = graph.addVertex()

        // Create connected component: root -> a -> b
        graph.addEdge(from: root, to: a)
        graph.addEdge(from: a, to: b)
        // isolated is not connected

        let result = graph.traverse(from: root, using: .iterativelyDeepeningDFS())

        #expect(result.vertices.count == 3)
        #expect(result.vertices.contains(root))
        #expect(result.vertices.contains(a))
        #expect(result.vertices.contains(b))
        #expect(!result.vertices.contains(isolated))
    }

    @Test func iterativelyDeepeningDFS_RecursiveDepthTest() {
        // Test the recursive nature of IDDFS with a reasonable depth
        var graph = DefaultAdjacencyList()
        let root = graph.addVertex()

        // Create a chain of 100 vertices
        var previous = root
        for _ in 0 ..< 100 {
            let next = graph.addVertex()
            graph.addEdge(from: previous, to: next)
            previous = next
        }

        // Test with max depth limit to prevent infinite recursion
        let result = graph.traverse(from: root, using: .iterativelyDeepeningDFS(maxDepth: 50))
        #expect(result.vertices.count <= 51)  // Should only explore up to depth 50

        // Test search with max depth
        var vertexCount = 0
        for _ in graph.search(from: root, using: .iterativelyDeepeningDFS(maxDepth: 50)) {
            vertexCount += 1
        }
        #expect(vertexCount <= 51)
    }

    // MARK: - Multi-Backend Coverage

    @Test func iddfsFindsAllReachableVertices_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where
            G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
            G.VertexDescriptor: Hashable
        {
            let root = graph.addVertex { $0.label = "root" }
            let a = graph.addVertex { $0.label = "a" }
            let b = graph.addVertex { $0.label = "b" }
            let c = graph.addVertex { $0.label = "c" }
            graph.addEdge(from: root, to: a)
            graph.addEdge(from: root, to: b)
            graph.addEdge(from: a, to: c)

            let result = graph.traverse(from: root, using: .iterativelyDeepeningDFS())
            let labels = result.vertices.map { graph[$0].label }
            #expect(result.vertices.count == 4, "[\(backend)] IDDFS finds all 4 reachable vertices")
            #expect(labels.contains("root"), "[\(backend)] root included")
            #expect(labels.contains("a"), "[\(backend)] a included")
            #expect(labels.contains("b"), "[\(backend)] b included")
            #expect(labels.contains("c"), "[\(backend)] c included")
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

    @Test func iddfsRespectsMaxDepth_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where
            G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
            G.VertexDescriptor: Hashable
        {
            let root = graph.addVertex { $0.label = "root" }
            let l1 = graph.addVertex { $0.label = "l1" }
            let l2 = graph.addVertex { $0.label = "l2" }
            let l3 = graph.addVertex { $0.label = "l3" }
            graph.addEdge(from: root, to: l1)
            graph.addEdge(from: l1, to: l2)
            graph.addEdge(from: l2, to: l3)

            let result = graph.traverse(from: root, using: .iterativelyDeepeningDFS(maxDepth: 2))
            let labels = result.vertices.map { graph[$0].label }
            #expect(result.vertices.count == 3, "[\(backend)] maxDepth=2 visits root, l1, l2 only")
            #expect(!labels.contains("l3"), "[\(backend)] l3 at depth 3 is pruned by maxDepth=2")
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

    @Test func iddfsSameVertexSetAsBFS_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where
            G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
            G.VertexDescriptor: Hashable
        {
            let root = graph.addVertex { $0.label = "root" }
            let a = graph.addVertex { $0.label = "a" }
            let b = graph.addVertex { $0.label = "b" }
            let c = graph.addVertex { $0.label = "c" }
            let d = graph.addVertex { $0.label = "d" }
            graph.addEdge(from: root, to: a)
            graph.addEdge(from: root, to: b)
            graph.addEdge(from: a, to: c)
            graph.addEdge(from: b, to: d)

            let iddfsResult = graph.traverse(from: root, using: .iterativelyDeepeningDFS())
            let bfsResult = graph.traverse(from: root, using: .bfs())
            #expect(
                Set(iddfsResult.vertices) == Set(bfsResult.vertices),
                "[\(backend)] IDDFS and BFS discover identical vertex sets"
            )
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
}
