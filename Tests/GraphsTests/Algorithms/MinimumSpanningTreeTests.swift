#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
    @testable import Graphs
    import Testing

    struct MinimumSpanningTreeTests {

        // MARK: - Test Data

        func createTestGraph() -> AdjacencyList {
            var graph = AdjacencyList()

            // Create a simple graph: A-B-C with weights 1, 2, 3
            // A --1-- B --2-- C
            // |              |
            // 3              4
            // |              |
            // D --5-- E --6-- F

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }
            let e = graph.addVertex { $0.label = "E" }
            let f = graph.addVertex { $0.label = "F" }

            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: a) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: c) { $0.weight = 2.0 }
            graph.addEdge(from: c, to: b) { $0.weight = 2.0 }
            graph.addEdge(from: a, to: d) { $0.weight = 3.0 }
            graph.addEdge(from: d, to: a) { $0.weight = 3.0 }
            graph.addEdge(from: c, to: f) { $0.weight = 4.0 }
            graph.addEdge(from: f, to: c) { $0.weight = 4.0 }
            graph.addEdge(from: d, to: e) { $0.weight = 5.0 }
            graph.addEdge(from: e, to: d) { $0.weight = 5.0 }
            graph.addEdge(from: e, to: f) { $0.weight = 6.0 }
            graph.addEdge(from: f, to: e) { $0.weight = 6.0 }

            return graph
        }

        // MARK: - Core Behavior (Kruskal)

        @Test func kruskalBuildsMinimumTree() {
            let graph = createTestGraph()

            let mst = graph.minimumSpanningTree(using: .kruskal(weight: .property(\.weight)))

            // The MST should have 5 edges (6 vertices - 1)
            #expect(mst.edgeCount == 5)

            // The MST should include all 6 vertices
            #expect(mst.vertexCount == 6)

            // The total weight should be 1 + 2 + 3 + 4 + 5 = 15
            #expect(mst.totalWeight == 15.0)
        }

        @Test func kruskalHandlesDisconnectedGraph() {
            var graph = AdjacencyList()

            // Create two disconnected components
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: a) { $0.weight = 1.0 }
            graph.addEdge(from: c, to: d) { $0.weight = 2.0 }
            graph.addEdge(from: d, to: c) { $0.weight = 2.0 }

            let mst = graph.minimumSpanningTree(using: .kruskal(weight: .property(\.weight)))

            // The MST should have 2 edges (4 vertices - 2 components)
            #expect(mst.edgeCount == 2)

            // The MST should include all 4 vertices
            #expect(mst.vertexCount == 4)

            // The total weight should be 1 + 2 = 3
            #expect(mst.totalWeight == 3.0)
        }

        // MARK: - Core Behavior (Prim)

        @Test func primBuildsMinimumTree() {
            let graph = createTestGraph()

            let mst = graph.minimumSpanningTree(using: .prim(weight: .property(\.weight)))

            // The MST should have 5 edges (6 vertices - 1)
            #expect(mst.edgeCount == 5)

            // The MST should include all 6 vertices
            #expect(mst.vertexCount == 6)

            // The total weight should be 1 + 2 + 3 + 4 + 5 = 15
            #expect(mst.totalWeight == 15.0)
        }

        @Test func primStartsFromAnyVertex() {
            let graph = createTestGraph()

            // Get the first vertex to use as start
            let firstVertex = Array(graph.vertices()).first!

            let mst = graph.minimumSpanningTree(using: .prim(weight: .property(\.weight), startVertex: firstVertex))

            // The MST should have 5 edges (6 vertices - 1)
            #expect(mst.edgeCount == 5)

            // The MST should include all 6 vertices
            #expect(mst.vertexCount == 6)

            // The total weight should be 1 + 2 + 3 + 4 + 5 = 15
            #expect(mst.totalWeight == 15.0)
        }

        // MARK: - Core Behavior (Borůvka)

        @Test func boruvkaBuildsMinimumTree() {
            let graph = createTestGraph()

            let mst = graph.minimumSpanningTree(using: .boruvka(weight: .property(\.weight)))

            // The MST should have 5 edges (6 vertices - 1)
            #expect(mst.edgeCount == 5)

            // The MST should include all 6 vertices
            #expect(mst.vertexCount == 6)

            // The total weight should be 1 + 2 + 3 + 4 + 5 = 15
            #expect(mst.totalWeight == 15.0)
        }

        // MARK: - Algorithm Comparison

        @Test func allAlgorithmsAgreeTotalWeight() {
            let graph = createTestGraph()

            let kruskalMST = graph.minimumSpanningTree(using: .kruskal(weight: .property(\.weight)))
            let primMST = graph.minimumSpanningTree(using: .prim(weight: .property(\.weight)))
            let boruvkaMST = graph.minimumSpanningTree(using: .boruvka(weight: .property(\.weight)))

            // All algorithms should produce the same total weight
            #expect(kruskalMST.totalWeight == primMST.totalWeight)
            #expect(primMST.totalWeight == boruvkaMST.totalWeight)

            // All algorithms should produce the same number of edges
            #expect(kruskalMST.edgeCount == primMST.edgeCount)
            #expect(primMST.edgeCount == boruvkaMST.edgeCount)

            // All algorithms should include the same vertices
            #expect(kruskalMST.vertexCount == primMST.vertexCount)
            #expect(primMST.vertexCount == boruvkaMST.vertexCount)
        }

        // MARK: - Multi-Backend Coverage

        @Test func kruskalAndPrimAgreeTotalWeight_allBackends() {
            func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
            where
                G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
                G.VertexDescriptor: Hashable, G: EdgeListGraph, G.EdgeDescriptor: Equatable
            {
                // Connected undirected graph (both directions per edge)
                let a = graph.addVertex { $0.label = "A" }
                let b = graph.addVertex { $0.label = "B" }
                let c = graph.addVertex { $0.label = "C" }
                let d = graph.addVertex { $0.label = "D" }
                graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
                graph.addEdge(from: b, to: a) { $0.weight = 1.0 }
                graph.addEdge(from: b, to: c) { $0.weight = 2.0 }
                graph.addEdge(from: c, to: b) { $0.weight = 2.0 }
                graph.addEdge(from: c, to: d) { $0.weight = 3.0 }
                graph.addEdge(from: d, to: c) { $0.weight = 3.0 }
                graph.addEdge(from: a, to: d) { $0.weight = 9.0 }
                graph.addEdge(from: d, to: a) { $0.weight = 9.0 }

                let kruskal = graph.minimumSpanningTree(using: .kruskal(weight: .property(\.weight)))
                let prim = graph.minimumSpanningTree(using: .prim(weight: .property(\.weight)))

                #expect(kruskal.edgeCount == 3, "[\(backend)] Kruskal MST has V-1 edges")
                #expect(prim.edgeCount == 3, "[\(backend)] Prim MST has V-1 edges")
                #expect(kruskal.totalWeight == prim.totalWeight, "[\(backend)] Kruskal and Prim must agree on total weight")
            }
            var g1 = AdjacencyList()
            check(&g1, "default")
            var g4 = AdjacencyMatrix()
            check(&g4, "Matrix")
            #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
                var g2 = StorageBackedAdjacencyList(edgeStorage: CSREdgeStorage().cacheInOutEdges())
                check(&g2, "CSR")
                var g3 = StorageBackedAdjacencyList(edgeStorage: COOEdgeStorage().cacheInOutEdges())
                check(&g3, "COO")
            #endif
        }

        @Test func mstSpansAllVertices_allBackends() {
            func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
            where
                G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
                G.VertexDescriptor: Hashable, G: EdgeListGraph
            {
                let a = graph.addVertex()
                let b = graph.addVertex()
                let c = graph.addVertex()
                let d = graph.addVertex()
                graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
                graph.addEdge(from: b, to: a) { $0.weight = 1.0 }
                graph.addEdge(from: b, to: c) { $0.weight = 2.0 }
                graph.addEdge(from: c, to: b) { $0.weight = 2.0 }
                graph.addEdge(from: c, to: d) { $0.weight = 1.0 }
                graph.addEdge(from: d, to: c) { $0.weight = 1.0 }
                let mst = graph.minimumSpanningTree(using: .kruskal(weight: .property(\.weight)))
                #expect(mst.vertexCount == 4, "[\(backend)] MST spans all 4 vertices")
                #expect(mst.edgeCount == 3, "[\(backend)] MST has V-1 = 3 edges")
            }
            var g1 = AdjacencyList()
            check(&g1, "default")
            var g4 = AdjacencyMatrix()
            check(&g4, "Matrix")
            #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
                var g2 = StorageBackedAdjacencyList(edgeStorage: CSREdgeStorage().cacheInOutEdges())
                check(&g2, "CSR")
                var g3 = StorageBackedAdjacencyList(edgeStorage: COOEdgeStorage().cacheInOutEdges())
                check(&g3, "COO")
            #endif
        }

        // MARK: - Edge Cases

        @Test func singleVertexGraphHasNoEdges() {
            var graph = AdjacencyList()
            graph.addVertex { $0.label = "A" }
            let mst = graph.minimumSpanningTree(using: .kruskal(weight: .property(\.weight)))
            #expect(mst.edgeCount == 0)
            #expect(mst.vertexCount == 1)
            #expect(mst.totalWeight == 0.0)
        }

        @Test func twoVertexGraphHasSingleEdge() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            graph.addEdge(from: a, to: b) { $0.weight = 5.0 }
            graph.addEdge(from: b, to: a) { $0.weight = 5.0 }
            let mst = graph.minimumSpanningTree(using: .kruskal(weight: .property(\.weight)))
            #expect(mst.edgeCount == 1)
            #expect(mst.vertexCount == 2)
            #expect(mst.totalWeight == 5.0)
        }

        @Test func emptyGraphHasNoMST() {
            let graph = AdjacencyList()
            let mst = graph.minimumSpanningTree(using: .kruskal(weight: .property(\.weight)))
            #expect(mst.edgeCount == 0)
            #expect(mst.vertexCount == 0)
            #expect(mst.totalWeight == 0.0)
        }

        /// When two parallel edges connect the same pair of vertices, the MST must use
        /// only the cheaper one.
        ///
        /// Kruskal and Prim both select minimum-weight edges, so parallel edges with different
        /// weights must not both appear in the MST — only the cheaper survives.
        @Test func parallelEdgesSelectsCheaperInMST() {
            var graph = AdjacencyList()
            let a = graph.addVertex()
            let b = graph.addVertex()
            let c = graph.addVertex()
            graph.addEdge(from: a, to: b) { $0.weight = 5.0 }
            graph.addEdge(from: b, to: a) { $0.weight = 5.0 }
            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: a) { $0.weight = 1.0 }  // cheaper parallel
            graph.addEdge(from: b, to: c) { $0.weight = 2.0 }
            graph.addEdge(from: c, to: b) { $0.weight = 2.0 }

            let kruskal = graph.minimumSpanningTree(using: .kruskal(weight: .property(\.weight)))

            // MST should use weight-1 edge a−b and weight-2 edge b−c, total = 3
            #expect(kruskal.edgeCount == 2, "MST of a 3-vertex graph has exactly 2 edges")
            #expect(kruskal.totalWeight == 3.0, "MST must select cheaper a−b (w=1) and b−c (w=2)")
        }

        // MARK: - Observation Support

        /// Kruskal fires `examineEdge` for every candidate edge (including those that would create a
        /// cycle) and `edgeAdded` only for edges selected into the MST. Each observation in an
        /// ordered chain must see the same events.
        @Test func kruskalComposedObservationsReceiveAllEvents() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            // Undirected chain a−b−c: each undirected edge stored as two directed edges
            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: a) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: c) { $0.weight = 2.0 }
            graph.addEdge(from: c, to: b) { $0.weight = 2.0 }

            var examined1 = 0
            var examined2 = 0
            var added1 = 0
            var added2 = 0

            typealias Algorithm = Kruskal<AdjacencyList, Double>
            typealias Cases = MinimumSpanningTreeEventCases<Algorithm.Vertex, Algorithm.Edge, Double>
            let algorithm = Algorithm(edgeWeight: .property(\.weight))
                .observing(Cases.edgeExamined) { _ in examined1 += 1 }
                .observing(Cases.edgeAdded) { _ in added1 += 1 }
                .observing(Cases.edgeExamined) { _ in examined2 += 1 }
                .observing(Cases.edgeAdded) { _ in added2 += 1 }

            _ = graph.minimumSpanningTree(using: algorithm)

            // All 4 directed edges are examined; 2 are added to the MST
            #expect(examined1 == 4, "Kruskal examines all 4 directed edges in the sorted order")
            #expect(examined2 == 4)
            #expect(added1 == 2, "Kruskal adds exactly 2 MST edges for a 3-vertex chain")
            #expect(added2 == 2)
            #expect(examined1 == examined2, "both composed observations must see the same edgeExamined events")
            #expect(added1 == added2, "both composed observations must see the same edgeAdded events")
        }

        /// Exercises all three emitted Prim events through an ordered observation chain.
        ///
        /// Graph: undirected chain a−b−c (4 directed edges).
        /// - `examineVertex` fires for each vertex visited by Prim.
        /// - `examineEdge` fires for each edge considered when selecting the minimum weight edge.
        /// - `addEdge` fires for each edge added to the MST (2 edges for a 3-vertex chain).
        @Test func primComposedObservationsReceiveAllEvents() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: a) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: c) { $0.weight = 2.0 }
            graph.addEdge(from: c, to: b) { $0.weight = 2.0 }

            var examined1 = 0
            var examined2 = 0
            var examEdge1 = 0
            var examEdge2 = 0
            var added1 = 0
            var added2 = 0

            typealias Algorithm = Prim<AdjacencyList, Double>
            typealias Cases = MinimumSpanningTreeEventCases<Algorithm.Vertex, Algorithm.Edge, Double>
            let algorithm = Algorithm(edgeWeight: .property(\.weight))
                .observing(Cases.vertexExamined) { _ in examined1 += 1 }
                .observing(Cases.edgeExamined) { _ in examEdge1 += 1 }
                .observing(Cases.edgeAdded) { _ in added1 += 1 }
                .observing(Cases.vertexExamined) { _ in examined2 += 1 }
                .observing(Cases.edgeExamined) { _ in examEdge2 += 1 }
                .observing(Cases.edgeAdded) { _ in added2 += 1 }

            _ = graph.minimumSpanningTree(using: algorithm)

            // Prim visits all 3 vertices, examines edges from each, and adds 2 MST edges
            #expect(examined1 >= 1, "examineVertex fires for each vertex visited by Prim")
            #expect(examined2 >= 1)
            #expect(examEdge1 >= 1, "examineEdge fires for each edge considered by Prim")
            #expect(examEdge2 >= 1)
            #expect(added1 == 2, "Prim adds exactly 2 MST edges for a 3-vertex chain")
            #expect(added2 == 2)
            // Both ordered observation groups must see identical event counts.
            #expect(examined1 == examined2)
            #expect(examEdge1 == examEdge2)
            #expect(added1 == added2)
        }

        /// Exercises all five emitted Borůvka events through an ordered observation chain.
        ///
        /// Graph: undirected chain a−b−c (4 directed edges stored as weight-carrying edge pairs).
        /// - `examineEdge` fires for every edge once, before the main loop begins.
        /// - `addEdge` fires for each edge added to the MST (2 for a 3-vertex chain).
        /// - `skipEdge` fires when an edge would create a cycle (same-component check).
        /// - `unionVertices` fires when two components are merged.
        /// - `completeComponentMerge` fires at the end of each Borůvka iteration.
        /// Both observation groups must see identical event counts.
        @Test func boruvkaComposedObservationsReceiveAllEvents() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: a) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: c) { $0.weight = 2.0 }
            graph.addEdge(from: c, to: b) { $0.weight = 2.0 }

            var examined1 = 0
            var examined2 = 0
            var added1 = 0
            var added2 = 0
            var skipped1 = 0
            var skipped2 = 0
            var union1 = 0
            var union2 = 0
            var complete1 = 0
            var complete2 = 0

            typealias Algorithm = Boruvka<AdjacencyList, Double>
            typealias Cases = MinimumSpanningTreeEventCases<Algorithm.Vertex, Algorithm.Edge, Double>
            let algorithm = Algorithm(edgeWeight: .property(\.weight))
                .observing(Cases.edgeExamined) { _ in examined1 += 1 }
                .observing(Cases.edgeAdded) { _ in added1 += 1 }
                .observing(Cases.edgeSkipped) { _ in skipped1 += 1 }
                .observing(Cases.verticesJoined) { _ in union1 += 1 }
                .observing(Cases.componentMergeFinished) { _ in complete1 += 1 }
                .observing(Cases.edgeExamined) { _ in examined2 += 1 }
                .observing(Cases.edgeAdded) { _ in added2 += 1 }
                .observing(Cases.edgeSkipped) { _ in skipped2 += 1 }
                .observing(Cases.verticesJoined) { _ in union2 += 1 }
                .observing(Cases.componentMergeFinished) { _ in complete2 += 1 }

            _ = graph.minimumSpanningTree(using: algorithm)

            // Borůvka examines all 4 directed edges before the main loop
            #expect(examined1 == 4, "examineEdge fires for all 4 directed edges")
            #expect(examined2 == 4)
            // MST for a 3-vertex chain has exactly 2 edges
            #expect(added1 == 2, "addEdge fires exactly 2 times for a 3-vertex chain MST")
            #expect(added2 == 2)
            // Each addEdge is paired with a unionVertices call
            #expect(union1 >= 1, "unionVertices fires when components are merged")
            #expect(union2 >= 1)
            // completeComponentMerge fires at the end of each Borůvka iteration
            #expect(complete1 >= 1, "completeComponentMerge fires once per iteration")
            #expect(complete2 >= 1)
            // Both ordered observation groups must see identical event counts.
            #expect(examined1 == examined2)
            #expect(added1 == added2)
            #expect(skipped1 == skipped2)
            #expect(union1 == union2)
            #expect(complete1 == complete2)
        }
    }
#endif
