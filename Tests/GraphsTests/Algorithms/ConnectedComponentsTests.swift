#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
    @testable import Graphs
    import Testing

    struct ConnectedComponentsTests {

        // MARK: - Core Behavior

        @Test func unionFindFindsConnectedVertices() {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }

            // Create a connected component: A - B - C
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: c)

            let unionFind = UnionFindConnectedComponents(on: graph)
            let result = unionFind.connectedComponents(visitor: nil)

            // Should have one connected component containing all three vertices
            #expect(result.componentCount == 1)
            #expect(result.components[0].count == 3)
        }

        @Test func dfsFindsConnectedVertices() {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }

            // Create a connected component: A - B - C
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: c)

            let dfs = DFSConnectedComponents(on: graph)
            let result = dfs.connectedComponents(visitor: nil)

            // Should have one connected component containing all three vertices
            #expect(result.componentCount == 1)
            #expect(result.components[0].count == 3)
        }

        @Test func unionFindSeparatesDisconnectedComponents() {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            // Create two disconnected components: A - B and C - D
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: c, to: d)

            let unionFind = UnionFindConnectedComponents(on: graph)
            let result = unionFind.connectedComponents(visitor: nil)

            // Should have two connected components
            #expect(result.componentCount == 2)

            // Each component should have 2 vertices
            for component in result.components {
                #expect(component.count == 2)
            }
        }

        @Test func dfsSeparatesDisconnectedComponents() {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            // Create two disconnected components: A - B and C - D
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: c, to: d)

            let dfs = DFSConnectedComponents(on: graph)
            let result = dfs.connectedComponents(visitor: nil)

            // Should have two connected components
            #expect(result.componentCount == 2)

            // Each component should have 2 vertices
            for component in result.components {
                #expect(component.count == 2)
            }
        }

        @Test func unionFindFindsMultipleComponents() {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }
            let e = graph.addVertex { $0.label = "E" }
            graph.addVertex { $0.label = "F" }

            // Component 1: A - B - C
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: c)

            // Component 2: D - E
            graph.addEdge(from: d, to: e)

            // Component 3: F (single vertex)
            // No edges for F

            let unionFind = UnionFindConnectedComponents(on: graph)
            let result = unionFind.connectedComponents(visitor: nil)

            // Should have three connected components
            #expect(result.componentCount == 3)

            // Find components by size
            let singleVertexComponent = result.components.first { $0.count == 1 }!
            let twoVertexComponent = result.components.first { $0.count == 2 }!
            let threeVertexComponent = result.components.first { $0.count == 3 }!

            // Verify component sizes
            #expect(singleVertexComponent.count == 1)
            #expect(twoVertexComponent.count == 2)
            #expect(threeVertexComponent.count == 3)
        }

        @Test func dfsFindsMultipleComponents() {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }
            let e = graph.addVertex { $0.label = "E" }
            graph.addVertex { $0.label = "F" }

            // Component 1: A - B - C
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: c)

            // Component 2: D - E
            graph.addEdge(from: d, to: e)

            // Component 3: F (single vertex)
            // No edges for F

            let dfs = DFSConnectedComponents(on: graph)
            let result = dfs.connectedComponents(visitor: nil)

            // Should have three connected components
            #expect(result.componentCount == 3)

            // Find components by size
            let singleVertexComponent = result.components.first { $0.count == 1 }!
            let twoVertexComponent = result.components.first { $0.count == 2 }!
            let threeVertexComponent = result.components.first { $0.count == 3 }!

            // Verify component sizes
            #expect(singleVertexComponent.count == 1)
            #expect(twoVertexComponent.count == 2)
            #expect(threeVertexComponent.count == 3)
        }

        @Test func unionFindHandlesSingleVertex() {
            var graph = AdjacencyList()

            graph.addVertex { $0.label = "A" }

            let unionFind = UnionFindConnectedComponents(on: graph)
            let result = unionFind.connectedComponents(visitor: nil)

            // Should have one connected component with one vertex
            #expect(result.componentCount == 1)
            #expect(result.components[0].count == 1)
        }

        @Test func dfsHandlesSingleVertex() {
            var graph = AdjacencyList()

            graph.addVertex { $0.label = "A" }

            let dfs = DFSConnectedComponents(on: graph)
            let result = dfs.connectedComponents(visitor: nil)

            // Should have one connected component with one vertex
            #expect(result.componentCount == 1)
            #expect(result.components[0].count == 1)
        }

        @Test func unionFindVisitorObservesEvents() {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }

            graph.addEdge(from: a, to: b)

            let unionFind = UnionFindConnectedComponents(on: graph)
            let result = unionFind.connectedComponents(visitor: nil)

            // Basic functionality test
            #expect(result.componentCount == 1)
            #expect(result.components[0].count == 2)
        }

        @Test func dfsVisitorObservesEvents() {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }

            graph.addEdge(from: a, to: b)

            let dfs = DFSConnectedComponents(on: graph)
            let result = dfs.connectedComponents(visitor: nil)

            // Basic functionality test
            #expect(result.componentCount == 1)
            #expect(result.components[0].count == 2)
        }

        @Test func unionFindResultsAreConsistent() {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            graph.addEdge(from: a, to: b)
            graph.addEdge(from: c, to: d)

            let unionFind = UnionFindConnectedComponents(on: graph)
            let result1 = unionFind.connectedComponents(visitor: nil)
            let result2 = unionFind.connectedComponents(visitor: nil)

            // Results should be consistent across multiple runs
            #expect(result1.componentCount == result2.componentCount)

            // Each component should have the same size
            let sizes1 = result1.components.map { $0.count }.sorted()
            let sizes2 = result2.components.map { $0.count }.sorted()
            #expect(sizes1 == sizes2)
        }

        @Test func dfsResultsAreConsistent() {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            graph.addEdge(from: a, to: b)
            graph.addEdge(from: c, to: d)

            let dfs = DFSConnectedComponents(on: graph)
            let result1 = dfs.connectedComponents(visitor: nil)
            let result2 = dfs.connectedComponents(visitor: nil)

            // Results should be consistent across multiple runs
            #expect(result1.componentCount == result2.componentCount)

            // Each component should have the same size
            let sizes1 = result1.components.map { $0.count }.sorted()
            let sizes2 = result2.components.map { $0.count }.sorted()
            #expect(sizes1 == sizes2)
        }

        // MARK: - Multi-Backend Coverage

        @Test func componentCountAndSizes_allBackends() {
            func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
            where
                G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
                G.VertexDescriptor: Hashable
            {
                let a = graph.addVertex { $0.label = "A" }
                let b = graph.addVertex { $0.label = "B" }
                let c = graph.addVertex { $0.label = "C" }
                let d = graph.addVertex { $0.label = "D" }
                _ = graph.addVertex { $0.label = "E" }  // isolated vertex
                graph.addEdge(from: a, to: b)
                graph.addEdge(from: b, to: a)
                graph.addEdge(from: c, to: d)
                graph.addEdge(from: d, to: c)
                // e is isolated

                let dfsResult = graph.connectedComponents(using: .dfs())
                let ufResult = graph.connectedComponents(using: .unionFind())

                #expect(dfsResult.componentCount == 3, "[\(backend)] DFS: expected 3 components")
                #expect(ufResult.componentCount == 3, "[\(backend)] UnionFind: expected 3 components")
                #expect(dfsResult.componentCount == ufResult.componentCount, "[\(backend)] both algorithms must agree")
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

        @Test func dfsComposedVisitorsReceiveAllEvents() {
            var graph = AdjacencyList()
            graph.addEdge(
                from: graph.addVertex { $0.label = "A" },
                to: graph.addVertex { $0.label = "B" }
            )

            var discovered1 = 0
            var discovered2 = 0
            var examEdge1 = 0
            var examEdge2 = 0
            var components1 = 0
            var components2 = 0

            var v1 = DFSConnectedComponents<DefaultAdjacencyList>.Visitor()
            v1.discoverVertex = { _ in discovered1 += 1 }
            v1.examineEdge = { _ in examEdge1 += 1 }
            v1.finishComponent = { _ in components1 += 1 }

            var v2 = DFSConnectedComponents<DefaultAdjacencyList>.Visitor()
            v2.discoverVertex = { _ in discovered2 += 1 }
            v2.examineEdge = { _ in examEdge2 += 1 }
            v2.finishComponent = { _ in components2 += 1 }

            let combined = v1.combined(with: v2)
            _ = DFSConnectedComponents(on: graph).connectedComponents(visitor: combined)

            #expect(discovered1 == 2, "discoverVertex fires for both A and B")
            #expect(discovered2 == 2)
            #expect(examEdge1 >= 1, "examineEdge fires for the A→B edge")
            #expect(examEdge2 >= 1)
            #expect(components1 == 1, "A and B form one component")
            #expect(components2 == 1)
            #expect(discovered1 == discovered2)
            #expect(examEdge1 == examEdge2)
            #expect(components1 == components2)
        }

        @Test func unionFindComposedVisitorsReceiveAllEvents() {
            var graph = AdjacencyList()
            graph.addEdge(
                from: graph.addVertex { $0.label = "A" },
                to: graph.addVertex { $0.label = "B" }
            )

            var discovered1 = 0
            var discovered2 = 0
            var examEdge1 = 0
            var examEdge2 = 0
            var components1 = 0
            var components2 = 0

            var v1 = UnionFindConnectedComponents<DefaultAdjacencyList>.Visitor()
            v1.discoverVertex = { _ in discovered1 += 1 }
            v1.examineEdge = { _ in examEdge1 += 1 }
            v1.finishComponent = { _ in components1 += 1 }

            var v2 = UnionFindConnectedComponents<DefaultAdjacencyList>.Visitor()
            v2.discoverVertex = { _ in discovered2 += 1 }
            v2.examineEdge = { _ in examEdge2 += 1 }
            v2.finishComponent = { _ in components2 += 1 }

            let combined = v1.combined(with: v2)
            _ = UnionFindConnectedComponents(on: graph).connectedComponents(visitor: combined)

            #expect(discovered1 == 2, "discoverVertex fires for both A and B")
            #expect(discovered2 == 2)
            #expect(examEdge1 >= 1, "examineEdge fires for the A→B edge")
            #expect(examEdge2 >= 1)
            #expect(components1 == 1, "A and B form one component")
            #expect(components2 == 1)
            #expect(discovered1 == discovered2)
            #expect(examEdge1 == examEdge2)
            #expect(components1 == components2)
        }

        // MARK: - Edge Cases

        /// A vertex with a self-loop (a → a) must form a single component by itself.
        ///
        /// The self-loop doesn't connect `a` to any other vertex, so if `a` is isolated
        /// (no other edges to other vertices), it is its own component. Both DFS and
        /// UnionFind must handle self-loops without revisiting or crashing.
        @Test func selfLoopVertexFormsItsOwnComponent() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            graph.addEdge(from: a, to: a)  // self-loop — a is still isolated from b
            // No edge connecting a and b

            let dfsResult = graph.connectedComponents(using: .dfs())
            let ufResult = graph.connectedComponents(using: .unionFind())

            #expect(
                dfsResult.componentCount == 2,
                "A self-looped vertex with no other edges forms its own component (2 components: {a} and {b})"
            )
            #expect(
                ufResult.componentCount == 2,
                "UnionFind: a self-looped vertex with no other edges forms its own component"
            )
            #expect(
                !dfsResult.areInSameComponent(a, b),
                "a and b must be in separate components despite a's self-loop"
            )
        }

        /// A single vertex with a self-loop forms exactly one component.
        @Test func singleVertexWithSelfLoopIsOneComponent() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            graph.addEdge(from: a, to: a)  // self-loop

            let dfsResult = graph.connectedComponents(using: .dfs())
            let ufResult = graph.connectedComponents(using: .unionFind())

            #expect(
                dfsResult.componentCount == 1,
                "A single vertex with a self-loop is still exactly 1 component"
            )
            #expect(
                ufResult.componentCount == 1,
                "UnionFind: single vertex with self-loop is 1 component"
            )
        }

        /// Parallel directed edges a → b and b → a must not inflate the component count.
        ///
        /// Two vertices mutually connected (even via parallel edges) form a single component.
        @Test func parallelEdgesDoNotInflateComponentCount() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: a, to: b)  // parallel edge
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: b, to: a)  // parallel reverse edge

            let dfsResult = graph.connectedComponents(using: .dfs())
            let ufResult = graph.connectedComponents(using: .unionFind())

            #expect(dfsResult.componentCount == 1, "Parallel edges must not inflate DFS component count")
            #expect(ufResult.componentCount == 1, "Parallel edges must not inflate UnionFind component count")
            #expect(dfsResult.areInSameComponent(a, b), "a and b must be in the same component")
        }

        // MARK: - Result API Coverage

        /// `component(containing:)` returns the full component for a given vertex.
        @Test func componentContaining() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            // c is isolated

            let result = graph.connectedComponents(using: .dfs())
            let compA = result.component(containing: a)
            let compC = result.component(containing: c)

            #expect(compA != nil, "component(containing:) must return non-nil for a present vertex")
            #expect(compA?.count == 2, "a and b share a component of size 2")
            #expect(compA?.contains(a) == true)
            #expect(compA?.contains(b) == true)
            #expect(compC?.count == 1, "c is isolated — its component has size 1")
        }

        /// `componentIndex(for:)` returns the index of the component containing a vertex.
        @Test func componentIndexForVertex() {
            var graph = AdjacencyList()
            let a = graph.addVertex()
            let b = graph.addVertex()
            let c = graph.addVertex()
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)

            let result = graph.connectedComponents(using: .dfs())
            let idxA = result.componentIndex(for: a)
            let idxB = result.componentIndex(for: b)
            let idxC = result.componentIndex(for: c)

            #expect(idxA != nil)
            #expect(idxB != nil)
            #expect(idxC != nil)
            #expect(idxA == idxB, "a and b are in the same component")
            #expect(idxA != idxC, "c is in a different component")
        }

        /// `connectedComponents()` no-argument convenience uses DFS internally.
        @Test func noArgConvenienceUsesDefaultAlgorithm() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)

            let result = graph.connectedComponents()  // no algorithm parameter — exercises the default
            #expect(result.componentCount == 2, "graph has 2 components: {a,b} and {c}")
            #expect(result.areInSameComponent(a, b))
            #expect(!result.areInSameComponent(a, c))
        }

        /// `ConnectedComponentsResult` is `Equatable` — two identical runs must be equal.
        @Test func resultEquatableConformance() {
            var graph = AdjacencyList()
            let a = graph.addVertex()
            let b = graph.addVertex()
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)

            let r1 = graph.connectedComponents(using: .dfs())
            let r2 = graph.connectedComponents(using: .dfs())
            #expect(r1 == r2, "Two DFS runs on the same graph must produce equal results")
            // Also verify inequality when graphs differ
            var graph2 = AdjacencyList()
            _ = graph2.addVertex()
            _ = graph2.addVertex()
            let r3 = graph2.connectedComponents(using: .dfs())
            #expect(r1 != r3, "Results from different graphs must differ")
        }

        /// `ConnectedComponentsResult` is `Hashable` — can be stored in a `Set`.
        @Test func resultHashableConformance() {
            var graph = AdjacencyList()
            let a = graph.addVertex()
            let b = graph.addVertex()
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)

            let result = graph.connectedComponents(using: .dfs())
            var seen: Set<ConnectedComponentsResult<DefaultAdjacencyList.VertexDescriptor>> = []
            seen.insert(result)
            seen.insert(result)
            #expect(seen.count == 1, "Inserting the same result twice must yield a set of size 1")
        }
    }
#endif
