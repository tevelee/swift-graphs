#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
    @testable import Graphs
    import Testing

    struct ArticulationPointsTests {

        // MARK: - Core Behavior

        @Test func linearChain() {
            // A - B - C (undirected, modeled as bidirectional edges)
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }

            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: b)

            let result = graph.articulationPoints()

            // B is a cut vertex
            #expect(result.cutVertices == [b])
            #expect(result.isArticulationPoint(b))
            #expect(!result.isArticulationPoint(a))
            #expect(!result.isArticulationPoint(c))

            // 2 bridge edges (one per undirected edge, tree edge direction only)
            #expect(result.bridges.count == 2)
        }

        @Test func cycle() {
            // A - B - C - A (triangle, no cut vertices, no bridges)
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }

            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: b)
            graph.addEdge(from: c, to: a)
            graph.addEdge(from: a, to: c)

            let result = graph.articulationPoints()

            #expect(result.cutVertices.isEmpty)
            #expect(result.bridges.isEmpty)
        }

        @Test func diamond() {
            // A-B, A-C, B-D, C-D (diamond shape)
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: a, to: c)
            graph.addEdge(from: c, to: a)
            graph.addEdge(from: b, to: d)
            graph.addEdge(from: d, to: b)
            graph.addEdge(from: c, to: d)
            graph.addEdge(from: d, to: c)

            let result = graph.articulationPoints()

            #expect(result.cutVertices.isEmpty)
            #expect(result.bridges.isEmpty)
        }

        @Test func twoTrianglesConnectedByBridge() {
            // Triangle 1: A-B-C-A, Triangle 2: D-E-F-D, bridge: C-D
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }
            let e = graph.addVertex { $0.label = "E" }
            let f = graph.addVertex { $0.label = "F" }

            // Triangle 1: A-B-C-A
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: b)
            graph.addEdge(from: c, to: a)
            graph.addEdge(from: a, to: c)

            // Bridge: C-D
            let bridgeCD = graph.addEdge(from: c, to: d)!
            graph.addEdge(from: d, to: c)

            // Triangle 2: D-E-F-D
            graph.addEdge(from: d, to: e)
            graph.addEdge(from: e, to: d)
            graph.addEdge(from: e, to: f)
            graph.addEdge(from: f, to: e)
            graph.addEdge(from: f, to: d)
            graph.addEdge(from: d, to: f)

            let result = graph.articulationPoints()

            // C and D are cut vertices (bridge endpoints)
            #expect(result.cutVertices.contains(c))
            #expect(result.cutVertices.contains(d))
            #expect(result.cutVertices.count == 2)

            // The bridge edge C->D (tree edge direction)
            #expect(result.bridges.count == 1)
            #expect(result.isBridge(bridgeCD))
        }

        @Test func singleVertex() {
            var graph = AdjacencyList()
            graph.addVertex { $0.label = "A" }

            let result = graph.articulationPoints()

            #expect(result.cutVertices.isEmpty)
            #expect(result.bridges.isEmpty)
        }

        @Test func twoVerticesOneEdge() {
            // A - B (single undirected edge)
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }

            let edgeAB = graph.addEdge(from: a, to: b)!
            graph.addEdge(from: b, to: a)

            let result = graph.articulationPoints()

            // No cut vertices (removing either leaves one isolated vertex, not a disconnection of multi-vertex components)
            #expect(result.cutVertices.isEmpty)

            // Tree edge direction is a bridge
            #expect(result.bridges.count == 1)
            #expect(result.isBridge(edgeAB))
        }

        @Test func disconnectedComponents() {
            // Component 1: A - B - C (chain)
            // Component 2: D - E (single edge)
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }
            let e = graph.addVertex { $0.label = "E" }

            // Component 1: A - B - C
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: b)

            // Component 2: D - E
            graph.addEdge(from: d, to: e)
            graph.addEdge(from: e, to: d)

            let result = graph.articulationPoints()

            // B is a cut vertex in component 1
            #expect(result.cutVertices.contains(b))

            // 3 bridges (tree edges: A->B, B->C, D->E)
            #expect(result.bridges.count == 3)
        }

        @Test func starGraph() {
            // Hub connected to spokes: H-A, H-B, H-C, H-D
            var graph = AdjacencyList()

            let hub = graph.addVertex { $0.label = "H" }
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            graph.addEdge(from: hub, to: a)
            graph.addEdge(from: a, to: hub)
            graph.addEdge(from: hub, to: b)
            graph.addEdge(from: b, to: hub)
            graph.addEdge(from: hub, to: c)
            graph.addEdge(from: c, to: hub)
            graph.addEdge(from: hub, to: d)
            graph.addEdge(from: d, to: hub)

            let result = graph.articulationPoints()

            // Hub is the only cut vertex
            #expect(result.cutVertices == [hub])
            #expect(result.isArticulationPoint(hub))

            // 4 bridge edges (tree edges from hub to each spoke)
            #expect(result.bridges.count == 4)
        }

        // MARK: - API Convenience

        @Test func defaultAlgorithmAPI() {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }

            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: b)

            // Default API
            let result = graph.articulationPoints()
            #expect(result.cutVertices == [b])
        }

        // MARK: - Multi-Backend Coverage

        @Test func cutVerticesDetected_allBackends() {
            func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
            where
                G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
                G.VertexDescriptor: Hashable, G.EdgeDescriptor: Hashable
            {
                // Linear chain A - B - C (undirected via bidirectional edges): B is the cut vertex
                let a = graph.addVertex { $0.label = "A" }
                let b = graph.addVertex { $0.label = "B" }
                let c = graph.addVertex { $0.label = "C" }
                graph.addEdge(from: a, to: b)
                graph.addEdge(from: b, to: a)
                graph.addEdge(from: b, to: c)
                graph.addEdge(from: c, to: b)

                let result = graph.articulationPoints()

                #expect(result.cutVertices.count == 1, "[\(backend)] only B is a cut vertex")
                #expect(result.isArticulationPoint(b), "[\(backend)] B must be detected as an articulation point")
                #expect(!result.isArticulationPoint(a), "[\(backend)] A is not a cut vertex")
                #expect(!result.isArticulationPoint(c), "[\(backend)] C is not a cut vertex")
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

        @Test func explicitAlgorithmAPI() {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }

            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: b)

            // Explicit algorithm selection
            let result = graph.articulationPoints(using: .tarjan())
            #expect(result.cutVertices == [b])
        }

        // MARK: - Visitor Support

        /// Exercises all seven TarjanArticulationPoints visitor events through a composed visitor pair.
        ///
        /// Graph: undirected triangle A−B−C−A (6 bidirectional directed edges) plus bridge A−D
        /// (2 directed edges). A is the only articulation point (DFS root with 2 tree children:
        /// B and D). The edge A−D is the only bridge.
        ///
        /// Event analysis:
        /// - `discoverVertex` fires for A, B, C, D (4 times).
        /// - `examineEdge` fires for all 8 directed edges.
        /// - `treeEdge` fires for a→b, b→c, and a→d (3 times).
        /// - `backEdge` fires for c→a: a is a DFS ancestor of c but NOT c's direct parent
        ///   (b is), so the implementation does not skip this edge as a "parent edge".
        ///   The direct-parent skipping mechanism silences b→a and c→b, which is why
        ///   a simple A−B−C chain has zero backEdge firings.
        /// - `finishVertex` fires for C, B, D, A (4 times).
        /// - `foundArticulationPoint` fires once for A.
        /// - `foundBridge` fires once for the a→d tree edge.
        @Test func composedVisitorsReceiveAllEvents() {
            // Triangle A-B-C (all 6 bidirectional directed edges) + bridge A-D (2 directed edges).
            // A is the DFS root. DFS order: a→b (tree) → b→c (tree) → c→a (backEdge, non-parent
            // ancestor) → back to a → a→d (tree). A has 2 tree children so it is the cut vertex.
            // The bridge is A-D (D's low-link stays at disc[D] > disc[A]).
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            // Triangle (undirected stored as bidirectional directed edges)
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: b)
            graph.addEdge(from: c, to: a)
            graph.addEdge(from: a, to: c)

            // Bridge
            graph.addEdge(from: a, to: d)
            graph.addEdge(from: d, to: a)

            var discovered1 = 0
            var discovered2 = 0
            var examEdge1 = 0
            var examEdge2 = 0
            var tree1 = 0
            var tree2 = 0
            var back1 = 0
            var back2 = 0
            var finished1 = 0
            var finished2 = 0
            var artPoints1 = 0
            var artPoints2 = 0
            var bridges1 = 0
            var bridges2 = 0

            var v1 = TarjanArticulationPoints<DefaultAdjacencyList>.Visitor()
            v1.discoverVertex = { _ in discovered1 += 1 }
            v1.examineEdge = { _ in examEdge1 += 1 }
            v1.treeEdge = { _ in tree1 += 1 }
            v1.backEdge = { _ in back1 += 1 }
            v1.finishVertex = { _ in finished1 += 1 }
            v1.foundArticulationPoint = { _ in artPoints1 += 1 }
            v1.foundBridge = { _ in bridges1 += 1 }

            var v2 = TarjanArticulationPoints<DefaultAdjacencyList>.Visitor()
            v2.discoverVertex = { _ in discovered2 += 1 }
            v2.examineEdge = { _ in examEdge2 += 1 }
            v2.treeEdge = { _ in tree2 += 1 }
            v2.backEdge = { _ in back2 += 1 }
            v2.finishVertex = { _ in finished2 += 1 }
            v2.foundArticulationPoint = { _ in artPoints2 += 1 }
            v2.foundBridge = { _ in bridges2 += 1 }

            let combined = v1.combined(with: v2)
            _ = TarjanArticulationPoints(on: graph).articulationPoints(visitor: combined)

            #expect(discovered1 == 4, "discoverVertex fires for A, B, C, D")
            #expect(discovered2 == 4)
            #expect(examEdge1 == 8, "examineEdge fires for all 8 directed edges")
            #expect(examEdge2 == 8)
            #expect(tree1 == 3, "treeEdge fires for a→b, b→c, and a→d")
            #expect(tree2 == 3)
            // c→a fires backEdge: a is a DFS ancestor of c but NOT c's direct parent (b is).
            // The skippedParentEdge mechanism silences b→a and c→b (direct-parent edges), but
            // not c→a.
            #expect(back1 >= 1, "backEdge fires for c→a (non-parent ancestor edge)")
            #expect(back2 >= 1)
            #expect(finished1 == 4, "finishVertex fires for all 4 vertices")
            #expect(finished2 == 4)
            #expect(artPoints1 == 1, "foundArticulationPoint fires once (A is the only cut vertex)")
            #expect(artPoints2 == 1)
            #expect(bridges1 == 1, "foundBridge fires once for the a−d bridge")
            #expect(bridges2 == 1)
            // Both composed visitors must see identical event counts
            #expect(discovered1 == discovered2)
            #expect(examEdge1 == examEdge2)
            #expect(tree1 == tree2)
            #expect(back1 == back2)
            #expect(finished1 == finished2)
            #expect(artPoints1 == artPoints2)
            #expect(bridges1 == bridges2)
        }
    }
#endif
